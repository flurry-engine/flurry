package uk.aidanlee.flurry.api.resources;

import haxe.io.Bytes;
import uk.aidanlee.flurry.api.resources.loaders.PageFrameLoader;
import uk.aidanlee.flurry.api.resources.loaders.MsdfFontLoader;
import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader;
import haxe.ds.Vector;
import haxe.io.Path;
import haxe.ds.ReadOnlyArray;
import haxe.Exception;
import haxe.exceptions.NotImplementedException;
import hxrx.IObserver;
import hxrx.IObservable;
import hxrx.ISubscription;
import hxrx.schedulers.IScheduler;
import hxrx.observables.Observables;
import hxrx.subscriptions.Empty;
import hxrx.subscriptions.Single;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.builtin.DataBlob;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

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
     * Loads the provided parcels resources into the system.
     * If a parcel in the list has already been added its resources will not be added again.
     * @param _parcels List parcel files to load.
     * @return Observable of loading progress (normalised 0 - 1)
     */
    public function load(_parcels : ReadOnlyArray<String>) : IObservable<Float>
    {
        return _parcels
            .fromIterable()
            .flatMap(parcel -> {
                return create(obs -> {
                    final parcelPath = assetsPath.join('$parcel.parcel');
                    final input      = parcelPath.toFile().openInput();
    
                    // Parcel should start with PRCL
                    if (input.readString(4) != 'PRCL')
                    {
                        throw new Exception('stream does not contain the PRCL magic bytes');
                    }
    
                    final pageFormat  = input.readByte();
                    final resourceIDs = [];
    
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
                                final page     = new PageResource(id, image.w, image.h, Bytes.ofData(image.bytes));
    
                                resourceIDs.push(page.id);
                                syncScheduler.scheduleNow(_ -> {
                                    addResource(page);
    
                                    return new Empty();
                                });
                            case 'PROC':
                                final procNameLen = input.readInt32();
                                final procName    = input.readString(procNameLen);
    
                                proc = resourceReaders[procName];
                            case 'RESR':
                                final resource = proc.unsafe().read(input);
    
                                resourceIDs.push(resource.id);
                                syncScheduler.scheduleNow(_ -> {
                                    addResource(resource);
    
                                    return new Empty();
                                });
                            case other:
                                throw new Exception('Unkown magic bytes of $other');
                        }
                    }
    
                    input.close();
    
                    syncScheduler.scheduleNow(_ -> {
                        loadedParcels[parcel] = new LoadedParcel(parcel, resourceIDs);
    
                        return new Empty();
                    });

                    obs.onNext(1.0);
                    obs.onCompleted();

                    return new Empty();
                });
            })
            .subscribeOn(workScheduler)
            .observeOn(syncScheduler)
            .scan(0.0, (acc, next) -> acc + (next / _parcels.length))
            .publish()
            .refCount();
    }

    /**
     * Free a parcel and its resources from the system.
     * @param _name Parcel name.
     */
    public function free(_name : String)
    {
        final loaded = loadedParcels[_name];

        if (loaded != null)
        {
            for (id in loaded.resources)
            {
                final resource = resources[id];

                if (resource != null)
                {
                    removeResource(resource);
                }
            }
        }
    }

    /**
     * Add a resource to this system.
     * If the resource has already been added to this system the reference count is increased by one.
     * @param _resource The resource to add.
     */
    public function addResource(_resource : Resource)
    {
        resources[_resource.id] = _resource;
        references[_resource.id]++;

        events.created.onNext(_resource);
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
            references[_resource.id] = 0;
            resources[_resource.id] = null;
        }
        else
        {
            references[_resource.id]--;
        }
    }

    /**
     * Retrieve a resource from the system based on its unique string name.
     * @param _name Name of the resource.
     * @param _type Class type of the resource.
     * @return Resource object.
     * @throws InvalidResourceTypeException If the resource cannot be cast to the specified resource class.
     * @throws ResourceNotFoundException If a resource with the provided name is not in the system.
     */
    public function get(_id : Int) : Resource
    {
        final loaded = resources[_id];
        if (loaded != null)
        {
            return loaded;
        }
        else
        {
            throw new ResourceNotFoundException(_id);
        }
    }
}

class InvalidResourceTypeException extends Exception
{
    public function new(_resource : String, _type : String)
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

private class LoadedParcel
{
    public final name : String;

    public final resources : Array<ResourceID>;

	public function new(_name, _resources)
    {
		name      = _name;
		resources = _resources;
	}
}