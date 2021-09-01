package uk.aidanlee.flurry.api.resources;

import haxe.Exception;
import haxe.io.Bytes;
import haxe.ds.Vector;
import haxe.ds.ReadOnlyArray;
import hxrx.IObservable;
import hxrx.observables.Observables;
import hxrx.subscriptions.Empty;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.builtin.DataBlobResource;
import uk.aidanlee.flurry.api.resources.loaders.MsdfFontLoader;
import uk.aidanlee.flurry.api.resources.loaders.PageFrameLoader;
import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader;

using hxrx.schedulers.IScheduler;
using hxrx.observables.Observables;
using Safety;

class ResourceSystem
{
    static final assetsPath = hx.files.Path.of('assets');

    /**
     * Event bus the resource system can fire events into as and when resources and created and removed.
     */
    final events : ResourceEvents;

    /**
     * The scheduler that will load the parcels.
     */
    final workScheduler : IScheduler;

    /**
     * The scheduler that will run all observers.
     * This should be set to a main thread scheduler if `workScheduler` will execute the subscribe function on a separate thread.
     */
    final syncScheduler : IScheduler;

    final resourceReaders : Map<String, ResourceReader>;

    final loadedParcels : Map<String, LoadedParcel>;

    final resources : Vector<Null<Resource>>;

    final references : Vector<Int>;

    /**
     * Creates a new resources system.
     * Allows the creation and loading of parcels and caching their resources.
     */
    public function new(_events : ResourceEvents, _loaders : Null<Array<ResourceReader>>, _workScheduler : IScheduler, _syncScheduler : IScheduler)
    {
        events             = _events;
        workScheduler      = _workScheduler;
        syncScheduler      = _syncScheduler;
        resourceReaders    = [];
        loadedParcels      = [];
        resources          = new Vector(uk.aidanlee.flurry.macros.Parcels.getTotalResourceCount());
        references         = new Vector(uk.aidanlee.flurry.macros.Parcels.getTotalResourceCount());

        for (loader in [ new DesktopShaderLoader(), new MsdfFontLoader(), new PageFrameLoader() ])
        {
            for (id in loader.ids())
            {
                resourceReaders[id] = loader;
            }
        }

        if (_loaders != null)
        {
            for (loader in _loaders)
            {
                for (id in loader.ids())
                {
                    resourceReaders[id] = loader;
                }
            }
        }
    }

    /**
     * Loads the provided parcels into the resource system.
     * Parcels will not start to be loaded until the returned observable is subscribed to.
     * 
     * Loading occurs on the task pool and progress, completion, and error notifications arrive on the main thread.
     * @param _parcels Array of parcels to load.
     * @return Observable which provides a normalised loading count.
     */
    public function load(_parcels : ReadOnlyArray<String>) : IObservable<Float>
    {
        return _parcels
            .fromIterable()
            .flatMap(parcel ->
                create(obs -> {
                    final parcelPath = assetsPath.join('$parcel.parcel');
                    final input      = parcelPath.toFile().openInput();
    
                    // Parcel should start with PRCL
                    if (input.readString(4) != 'PRCL')
                    {
                        obs.onError(new Exception('stream does not contain the PRCL magic bytes'));

                        return new Empty();
                    }
    
                    final resources   = input.readInt32();
                    final pageFormat  = input.readByte();
                    final resourceIDs = new Vector(resources);
                    final tickValue   = 1 / resources;
    
                    var index = 0;
                    var magic = '';
                    var proc  = null;
                    while ('STOP' != (magic = input.readString(4)))
                    {
                        switch magic
                        {
                            case 'PAGE':
                                final id       = input.readInt32();
                                final bytesLen = input.readInt32();
                                final bytes    = input.read(bytesLen);
                                final image    = stb.Image.load_from_memory(bytes.getData(), bytesLen, 4);
                                final page     = new DataBlobResource(new PageResource(new ResourceID(id), image.w, image.h), Bytes.ofData(image.bytes));
    
                                resourceIDs.set(index++, page.id);

                                obs.onNext(tickValue);

                                syncScheduler.scheduleFunction(addResource.bind(page));
                            case 'PROC':
                                final procNameLen = input.readInt32();
                                final procName    = input.readString(procNameLen);
    
                                proc = switch resourceReaders[procName]
                                {
                                    case null:
                                        obs.onError(new Exception('No resource reader found for resources produced with processor $procName'));

                                        return new Empty();
                                    case reader:
                                        reader;
                                }
                            case 'RESR':
                                final resource = proc.unsafe().read(input);

                                resourceIDs.set(index++, resource.id);

                                obs.onNext(tickValue);

                                syncScheduler.scheduleFunction(addResource.bind(resource));
                            case other:
                                obs.onError(new Exception('Unkown magic bytes of $other'));

                                return new Empty();
                        }
                    }
    
                    input.close();
    
                    syncScheduler.scheduleFunction(() -> loadedParcels[parcel] = new LoadedParcel(parcel, resourceIDs));

                    obs.onCompleted();

                    return new Empty();
                }))
            .scan(0.0, (acc, next) -> acc + (next / _parcels.length))
            .subscribeOn(workScheduler)
            .observeOn(syncScheduler)
            .publish()
            .refCount();
    }

    /**
     * Free a parcel and its resources from the system.
     * @param _name Parcel name.
     * @throws ParcelNotLoadedException if the parcel to free is not actually loaded.
     * @throws ResourceNotFoundException if one of the resources in the parcel to free is not currently in the system.
     */
    public function free(_name : String)
    {
        switch loadedParcels[_name]
        {
            case null:
                throw new ParcelNotLoadedException(_name);
            case loaded:
                for (id in loaded.resources)
                {
                    removeResource(get(id));
                }
        }
    }

    /**
     * Add a resource to this system.
     * The resource is passed into the created resource event if it has not yet been added to the system.
     * If the resource has already been added to this system the reference count is increased by one.
     * @param _resource The resource to add.
     */
    public function addResource(_resource : Resource)
    {
        final toAdd = switch Std.downcast(_resource, DataBlobResource)
        {
            case null: _resource;
            case blob: blob.resource;
        }

        switch resources[toAdd.id]
        {
            case null:
                resources[toAdd.id] = toAdd;
                references[toAdd.id] = 1;

                events.created.onNext(_resource);
            case _:
                references[toAdd.id]++;
        }
    }

    /**
     * Manually remove a resource from this system.
     * If there are multiple references to this resource the count is decreased by one.
     * The resource will only be fully removed once there are no references to it.
     * @param _resource The resource to remove.
     */
    public function removeResource(_resource : Resource)
    {
        if (references[_resource.id] <= 1)
        {
            events.removed.onNext(_resource);

            references[_resource.id] = 0;
            resources[_resource.id] = null;
        }
        else
        {
            references[_resource.id]--;
        }
    }

    /**
     * Return the resource object for the provided ID.
     * @param _id ID of the resource to return.
     * @throws ResourceNotFoundException if the resource is not currently loaded.
     */
    public function get(_id : Int)
    {
        return switch resources[_id]
        {
            case null:
                throw new ResourceNotFoundException(_id);
            case loaded:
                loaded.unsafe();
        }
    }

    /**
     * Return the resource object for the provided ID casted to a specific type.
     * @param _id ID of the resource to return.
     * @param _as Resource class to cast the resource object to.
     * @throws ResourceNotFoundException if the resource is not currently loaded.
     * @throws InvalidResourceTypeException if the resource cannot be casted to the provided type.
     */
    public function getAs<T : Resource>(_id : Int, _as : Class<T>)
    {
        return switch resources[_id]
        {
            case null:
                throw new ResourceNotFoundException(_id);
            case loaded:
                switch Std.downcast(loaded, _as)
                {
                    case null:
                        throw new InvalidResourceTypeException(_id, Type.getClassName(_as));
                    case typed:
                        typed;
                }
        }
    }
}

class InvalidResourceTypeException extends Exception
{
    public function new(_resource : Int, _type : String)
    {
        super('resource $_resource is not a $_type');
    }
}

class ResourceNotFoundException extends Exception
{
    public function new(_resource : Int)
    {
        super('failed to load "$_resource", it does not exist in the system');
    }
}

class ParcelNotLoadedException extends Exception
{
    public function new(_parcel : String)
    {
        super('parcel $_parcel is not currently loaded');
    }
}

private class LoadedParcel
{
    public final name : String;

    public final resources : Vector<ResourceID>;

	public function new(_name, _resources)
    {
		name      = _name;
		resources = _resources;
	}
}