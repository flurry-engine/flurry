package uk.aidanlee.flurry.api.resources;

import haxe.io.Bytes;
import uk.aidanlee.flurry.api.resources.loaders.PageFrameLoader;
import uk.aidanlee.flurry.api.resources.loaders.MsdfFontLoader;
import uk.aidanlee.flurry.api.resources.loaders.GdxSpriteSheetLoader;
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

    final loadedResources : Map<String, LoadedResource>;

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
        loadedResources    = [];

        for (loader in [ new DesktopShaderLoader(), new GdxSpriteSheetLoader(), new MsdfFontLoader(), new PageFrameLoader() ])
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
        for (parcel in _parcels)
        {
            final parcelPath = assetsPath.join('$parcel.parcel');
            final input      = parcelPath.toFile().openInput();

            // Parcel should start with PRCL
            if (input.readString(4) != 'PRCL')
            {
                throw new Exception('stream does not contain the PRCL magic bytes');
            }

            // Read the table meta
            if (input.readString(4) != 'TABL')
            {
                throw new Exception('stream does not contain the TABL header bytes');
            }

            final assetCount = input.readInt32();
            final pageCount  = input.readInt32();
            final pageFormat = input.readByte();
            final readAssets = new Array<Resource>();

            // For now read past the actual table contents, we don't really care about it.
            for (_ in 0...assetCount)
            {
                // Skip past the name length (size we read) plus two ints for the pos and length in the parcel.
                final nameLen = input.readInt32();
                final name    = input.readString(nameLen);

                final procLen = input.readInt32();
                final proc    = input.readString(procLen);

                final pos     = input.readInt32();
                final length  = input.readInt32();
            }

            // Read all page data
            for (i in 0...pageCount)
            {
                if (input.readString(4) != 'PAGE')
                {
                    throw new Exception('stream does not contain the PAGE header bytes');
                }

                final nameLen  = input.readInt32();
                final name     = input.readString(nameLen);

                final bytesLen = input.readInt32();
                final bytes    = input.read(bytesLen);
                final image    = stb.Image.load_from_memory(bytes.getData(), bytesLen, 4);

                readAssets.push(new PageResource(name, image.w, image.h, Bytes.ofData(image.bytes)));
            }

            // Read all user resources.
            var magic = '';
            while ('STOP' != (magic = input.readString(4)))
            {
                if (magic != 'RESR')
                {
                    throw new Exception('stream does not contain the RESR header bytes');
                }

                final procNameLen   = input.readInt32();
                final procName      = input.readString(procNameLen);
                final assetsForProc = input.readInt32();
                final processor     = resourceReaders[procName];

                if (processor != null)
                {
                    for (_ in 0...assetsForProc)
                    {
                        for (resource in processor.read(input))
                        {
                            readAssets.push(resource);
                        }
                    }
                }
                else
                {
                    throw new Exception('No processor found for $procName');
                }
            }

            input.close();

            for (asset in readAssets)
            {
                addResource(asset);
            }
        }
        
        return empty();
    }

    /**
     * Free a parcel and its resources from the system.
     * @param _name Parcel name.
     */
    public function free(_name : String)
    {
        final parcel = '$_name.parcel';
        final loaded = loadedParcels[parcel];

        if (loaded != null)
        {
            for (id in loaded.resources)
            {
                final cached = loadedResources[id];

                if (cached != null)
                {
                    if (cached.references <= 1)
                    {
                        loadedResources.remove(id);
        
                        events.removed.onNext(cached.resource);
                    }
                    else
                    {
                        cached.references--;
                    }
                }
            }

            loadedParcels.remove(parcel);
        }
    }

    /**
     * Add a resource to this system.
     * If the resource has already been added to this system the reference count is increased by one.
     * @param _resource The resource to add.
     */
    public function addResource(_resource : Resource)
    {
        final loaded = loadedResources[_resource.name];

        if (loaded != null)
        {
            loaded.references++;
        }
        else
        {
            loadedResources[_resource.name] = new LoadedResource(_resource);

            events.created.onNext(_resource);
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
        final loaded = loadedResources[_resource.name];

        if (loaded != null)
        {
            if (loaded.references <= 1)
            {
                loadedResources.remove(_resource.name);

                events.removed.onNext(loaded.resource);
            }
            else
            {
                loaded.references--;
            }
        }
    }

    public function getID(_name : String) : ResourceID
    {
        final loaded = loadedResources[_name];
        if (loaded != null)
        {
            return loaded.resource.id;
        }

        throw new ResourceNotFoundException(_name);
    }

    /**
     * Retrieve a resource from the system based on its unique string name.
     * @param _name Name of the resource.
     * @param _type Class type of the resource.
     * @return Resource object.
     * @throws InvalidResourceTypeException If the resource cannot be cast to the specified resource class.
     * @throws ResourceNotFoundException If a resource with the provided name is not in the system.
     */
    public function getByName<T : Resource>(_name : String, _type : Class<T>) : T
    {
        final loaded = loadedResources[_name];
        if (loaded != null)
        {
            final casted = Std.downcast(loaded.resource, _type);

            if (casted != null)
            {
                return casted;
            }
            else
            {
                throw new InvalidResourceTypeException(_name, Type.getClassName(_type));
            }
        }
        else
        {
            throw new ResourceNotFoundException(_name);
        }
    }

    /**
     * Retrieve a resource from the system based on its unique ID.
     * @param _id ID of the resource.
     * @param _type Class type of the resource.
     * @return Resource object.
     * @throws InvalidResourceTypeException If the resource cannot be cast to the specified resource class.
     * @throws ResourceNotFoundException If a resource with the provided ID is not in the system.
     */
    public function getByID<T : Resource>(_id : Int, _type : Class<T>) : T
    {
        throw new NotImplementedException();
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
    public function new(_resource : String)
    {
        super('failed to load "$_resource", it does not exist in the system');
    }
}

private class LoadedParcel
{
    public final name : String;

    public final pages : Vector<String>;

    public final resources : Vector<String>;

	public function new(_name, _pages, _resources)
    {
		name      = _name;
		pages     = _pages;
		resources = _resources;
	}
}

private class LoadedResource
{
    public final resource : Resource;

    public var references : Int;

    public function new(_resource)
    {
        resource   = _resource;
        references = 0;
    }
}