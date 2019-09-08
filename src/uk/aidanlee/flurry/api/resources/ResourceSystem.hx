package uk.aidanlee.flurry.api.resources;

import haxe.Exception;
import haxe.Unserializer;
import haxe.io.Path;
import haxe.zip.Uncompress;
import format.png.Tools;
import format.png.Reader;
import json2object.JsonParser;
import hx.concurrent.collection.Queue;
import hx.concurrent.executor.Executor;
import uk.aidanlee.flurry.api.resources.Parcel.ParcelList;
import uk.aidanlee.flurry.api.resources.Parcel.ParcelType;
import uk.aidanlee.flurry.api.resources.Parcel.ShaderInfoLayout;
import uk.aidanlee.flurry.api.resources.Resource.ParcelResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderSource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ShaderValue;
import uk.aidanlee.flurry.api.resources.Resource.ShaderBlock;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.TextResource;
import uk.aidanlee.flurry.api.resources.Resource.BytesResource;
import sys.io.abstractions.IFileSystem;

using Safety;

enum ParcelEventType
{
    Succeeded;
    Progress;
    Failed;
}

class ResourceSystem
{
    /**
     * Event bus the resource system can fire events into as and when resources and created and removed.
     */
    final events : ResourceEvents;

    /**
     * Access to the engines filesystem.
     */
    final fileSystem : IFileSystem;

    /**
     * All parcels loaded in this resource system.
     */
    final parcels : Map<String, Parcel>;

    /**
     * Map of a parcels ID to all the resources IDs contained within it.
     * Stored since the parcel could be modified by the user and theres no way to know whats inside a pre-packed parcel until its unpacked.
     */
    final parcelResources : Map<String, Array<String>>;

    /**
     * Reference to all other parcels this parcel depends on.
     */
    final parcelDependencies : Map<String, Array<String>>;

    /**
     * Map of all loaded resources by their ID.
     */
    final resourceCache : Map<String, Resource>;

    /**
     * Map of how many times a specific resource has been referenced.
     * Prevents storing multiple of the same resource and ensures they aren't removed when still in use.
     */
    final resourceReferences : Map<String, Int>;

    /**
     * Thread pool to load parcels without blocking the main thread.
     */
    final executor : Executor;

    /**
     * Async event queue so the main thread can be notified when a parcel has been loaded.
     * Main thread then adds the loaded resources to the cache. Removes the need for any manual locking on the cache map.
     */
    final queue : Queue<ParcelEvent>;

    /**
     * Creates a new resources system.
     * Allows the creation and loading of parcels and caching their resources.
     * 
     * @param _threads Number of active threads for loading parcels (defaults 1).
     */
    public function new(_events : ResourceEvents, _fileSystem : IFileSystem, _threads : Int = 1)
    {
        events             = _events;
        fileSystem         = _fileSystem;
        parcels            = [];
        parcelResources    = [];
        parcelDependencies = [];
        resourceCache      = [];
        resourceReferences = [];
        queue              = new Queue();
        executor           = Executor.create(_threads);
    }

    /**
     * Create a new parcel in this system.
     * @param _name Unique name of the parcel.
     * @param _list List of all of this parcels resources.
     */
    public function create(_type : ParcelType, ?_onLoaded : Array<Resource>->Void, ?_onProgress : Float->Void, ?_onFailed : String->Void) : Parcel
    {
        var name = switch _type
        {
            case Definition(_name, _): _name;
            case PrePackaged(_name): _name;
        }

        if (parcels.exists(name))
        {
            throw new ParcelAlreadyExistsException(name);
        }

        return parcels[name] = new Parcel(this, name, _type, _onLoaded, _onProgress, _onFailed);
    }

    /**
     * Load the provided parcel.
     * @param _parcel The parcel to load.
     * @throws ParcelAlreadyLoadedException When this parcel has already been loaded.
     * @throws ParcelNotAddedException When the provided parcel is not tracked by the system.
     */
    public function load(_parcel : Parcel)
    {
        if (parcelResources.exists(_parcel.name))
        {
            throw new ParcelAlreadyLoadedException(_parcel.name);
        }

        if (parcels.exists(_parcel.name))
        {
            switch parcels[_parcel.name].unsafe().type
            {
                case Definition(_, _definition): loadDefinition(_parcel.name, _definition);
                case PrePackaged(_name): loadPrePackaged(_name);
            }
        }
        else
        {
            throw new ParcelNotAddedException(_parcel.name);
        }
    }

    /**
     * Removes / decrements references to all the resources in the provided parcel.
     * @param _parcel The parcel to free.
     * @throws ParcelNotAddedException When the provided parcel is not loaded in the system.
     */
    public function free(_parcel : Parcel)
    {
        if (!parcelResources.exists(_parcel.name))
        {
            throw new ParcelNotAddedException(_parcel.name);
        }

        freeDependencies(parcelDependencies[_parcel.name].or([]));

        for (resource in parcelResources[_parcel.name].or([]))
        {
            if (resourceCache.exists(resource))
            {
                removeResource(resourceCache[resource].unsafe());
            }
        }

        parcelResources.remove(_parcel.name);
        parcelDependencies.remove(_parcel.name);
    }

    /**
     * Manually attempt to add a resource to this system.
     * @param _resource The resource to add.
     */
    public function addResource(_resource : Resource)
    {
        if (resourceReferences.exists(_resource.id))
        {
            resourceReferences[_resource.id] = resourceReferences[_resource.id].unsafe() + 1;
        }
        else
        {
            resourceReferences.set(_resource.id, 1);

            resourceCache[_resource.id] = _resource;

            events.created.dispatch(_resource);
        }
    }

    /**
     * Manually attempt to remove a resource from this system.
     * @param _resource The resource to remove.
     */
    public function removeResource(_resource : Resource)
    {
        if (resourceReferences.exists(_resource.id))
        {
            var referenceCount = resourceReferences[_resource.id].unsafe();
            if (referenceCount == 1)
            {
                if (resourceCache.exists(_resource.id))
                {
                    events.removed.dispatch(resourceCache[_resource.id].unsafe());
                    resourceCache.remove(_resource.id);
                }

                resourceReferences.remove(_resource.id);
            }
            else
            {
                resourceReferences[_resource.id] = (referenceCount - 1);
            }
        }
    }

    /**
     * Get a loaded resource from this system.
     * @param _id   ID of the resource.
     * @param _type Class type of the resource.
     * @return T
     */
    public function get<T : Resource>(_id : String, _type : Class<T>) : T
    {
        if (resourceCache.exists(_id))
        {
            var res = resourceCache[_id].unsafe();
            var obj = Std.downcast(res, _type);
            
            if (obj != null)
            {
                return obj;
            }

            throw new InvalidResourceTypeException(_id, Type.getClassName(_type));
        }
        
        throw new ResourceNotFoundException(_id, _id);
    }

    /**
     * Processes the resource system.
     * This should be called at regular intervals to retrieve parcel loading status from the separate threads.
     * If this is not frequently called then resource won't appear in the system and parcel loading information won't be available.
     */
    public function update()
    {
        var event = queue.pop();
        while (event != null)
        {
            switch event.type
            {
                case Succeeded: onParcelSucceeded(cast event);
                case Progress : onParcelProgress(cast event);
                case Failed   : onParcelFailed(cast event);
            }

            event = queue.pop();
        }
    }

    /**
     * Loads all the the resources in the list of a different thread.
     * @param _name Parcel unique ID
     * @param _list List of resources to load.
     */
    function loadDefinition(_name : String, _list : ParcelList)
    {
        /**
         * This function is ran in a seperate thread to load all the assets without blocking the main thread.
         * An event is fired with the loaded resources and parcel ID so the main thread can add them.
         */
        executor.submit(() -> {           
            try {
                var resources = new Array<Resource>();
                
                var totalResources = calculateTotalResources(_list);
                var loadedIndices  = 0;

                for (asset in _list.bytes)
                {
                    if (!fileSystem.file.exists(asset.path))
                    {
                        throw new ResourceNotFoundException(asset.id, asset.path);
                    }

                    resources.push(new BytesResource(asset.id, fileSystem.file.getBytes(asset.path)));

                    queue.push(new ParcelProgressEvent(_name, Progress, ++loadedIndices / totalResources ));
                }

                for (asset in _list.texts)
                {
                    if (!fileSystem.file.exists(asset.path))
                    {
                        throw new ResourceNotFoundException(asset.id, asset.path);
                    }

                    resources.push(new TextResource(asset.id, fileSystem.file.getText(asset.path)));

                    queue.push(new ParcelProgressEvent(_name, Progress, ++loadedIndices / totalResources ));
                }

                for (asset in _list.images)
                {
                    if (!fileSystem.file.exists(asset.path))
                    {
                        throw new ResourceNotFoundException(asset.id, asset.path);
                    }

                    var info = new Reader(fileSystem.file.read(asset.path)).read();
                    var head = Tools.getHeader(info);

                    resources.push(new ImageResource(asset.id, head.width, head.height, Tools.extract32(info)));

                    queue.push(new ParcelProgressEvent(_name, Progress, ++loadedIndices / totalResources ));
                }

                for (asset in _list.shaders)
                {
                    if (!fileSystem.file.exists(asset.path))
                    {
                        throw new ResourceNotFoundException(asset.id, asset.path);
                    }

                    var parser = new JsonParser<ShaderInfoLayout>();
                    parser.fromJson(fileSystem.file.getText(asset.path));

                    for (error in parser.errors)
                    {
                        throw error;
                    }

                    var layout = new ShaderLayout(
                        parser.value.textures,
                        [
                            for (b in parser.value.blocks) new ShaderBlock(b.name, b.binding, [
                                for (v in b.values) new ShaderValue(v.name, v.type)
                            ])
                        ]);
                    var sourceOGL3 = asset.ogl3 == null ? null : new ShaderSource(
                        asset.ogl3.compiled.or(false),
                        fileSystem.file.getBytes(asset.ogl3.vertex),
                        fileSystem.file.getBytes(asset.ogl3.fragment));
                    var sourceOGL4 = asset.ogl4 == null ? null : new ShaderSource(
                        asset.ogl4.compiled.or(false),
                        fileSystem.file.getBytes(asset.ogl4.vertex),
                        fileSystem.file.getBytes(asset.ogl4.fragment)
                    );
                    var sourceHLSL = asset.hlsl == null ? null : new ShaderSource(
                        asset.hlsl.compiled.or(false),
                        fileSystem.file.getBytes(asset.hlsl.vertex),
                        fileSystem.file.getBytes(asset.hlsl.fragment)
                    );

                    resources.push(new ShaderResource(asset.id, layout, sourceOGL3, sourceOGL4, sourceHLSL));

                    queue.push(new ParcelProgressEvent(_name, Progress, ++loadedIndices / totalResources ));
                }

                queue.push(new ParcelSucceededEvent(_name, Succeeded, resources, []));
            }
            catch (_exception : Exception)
            {
                queue.push(new ParcelFailedEvent(_name, Failed, _exception.message));
            }
        });
    }

    /**
     * Load a pre-packaged parcel from the disk.
     * @param _file Parcel file name.
     */
    function loadPrePackaged(_file : String)
    {
        executor.submit(() -> {
            try
            {
                loadParcelFromFile(_file);
            }
            catch (_exception : Exception)
            {
                queue.push(new ParcelFailedEvent(_file, Failed, _exception.message));
            }
        });
    }

    /**
     * Load a parcel from a file on disk.
     * @param _file Parcel file name.
     */
    function loadParcelFromFile(_file : String)
    {
        var path = Path.join([ 'assets', 'parcels', _file ]);

        if (!fileSystem.file.exists(path))
        {
            throw new ParcelNotFoundException(path);
        }

        var bytes  = Uncompress.run(fileSystem.file.getBytes(path));
        var loader = new Unserializer(bytes.toString());
        var parcel = (cast loader.unserialize() : ParcelResource);

        for (dependency in parcel.depends)
        {
            loadParcelFromFile(dependency);
        }

        queue.push(new ParcelSucceededEvent(parcel.name, Succeeded, parcel.assets, parcel.depends));
    }

    /**
     * Recursivly free the resources found in the provided parcels.
     * @param _parcels Parcels to free.
     */
    function freeDependencies(_parcels : Array<String>)
    {
        for (dep in _parcels)
        {
            for (rec in parcelDependencies[dep].or([]))
            {
                if (parcelDependencies.exists(rec))
                {
                    freeDependencies(parcelDependencies[rec].unsafe());
                }
            }

            for (res in parcelResources[dep].or([]))
            {
                if (resourceCache.exists(res))
                {
                    removeResource(resourceCache[res].unsafe());
                }
            }
        }
    }

    /**
     * Sums up to number of resources included in a parcel list.
     * @param _list Parcel list to sum.
     * @return Total number of resources.
     */
    function calculateTotalResources(_list : ParcelList) : Int
    {
        var total = 0;
        
        total += _list.bytes.length;
        total += _list.texts.length;
        total += _list.images.length;
        total += _list.shaders.length;

        return total;
    }

    /**
     * When a parcel is loaded this functions is called which adds or increments the reference count on resources in the cache.
     * If a user callback has been specified, it will be called.
     * @param _event Parcel event.
     */
    function onParcelSucceeded(_event : ParcelSucceededEvent)
    {
        var newResources = [];

        for (resource in _event.resources)
        {
            newResources.push(resource.id);

            addResource(resource);
        }

        parcelResources[_event.parcel] = newResources;
        parcelDependencies[_event.parcel] = _event.dependencies;

        if (parcels.exists(_event.parcel))
        {
            var parcel = parcels[_event.parcel].unsafe();
            if (parcel.onLoaded != null)
            {
                parcel.onLoaded(_event.resources);
            }
        }
    }

    /**
     * Once a parcel loader thread has loaded an asset the user defined progress event is called (if defined).
     * @param _event Parcel event.
     */
    function onParcelProgress(_event : ParcelProgressEvent)
    {
        if (parcels.exists(_event.parcel))
        {
            var parcel = parcels[_event.parcel].unsafe();
            if (parcel.onProgress != null)
            {
                parcel.onProgress(_event.progress);
            }
        }
    }

    /**
     * If a parcel fails to load the user defined failure event is called (if defined).
     * @param _event 
     */
    function onParcelFailed(_event : ParcelFailedEvent)
    {
        if (parcels.exists(_event.parcel))
        {
            var parcel = parcels[_event.parcel].unsafe();
            if (parcel.onFailed != null)
            {
                parcel.onFailed(_event.message);
            }
        }
    }
}

// #region exceptions

class ParcelNotFoundException extends Exception
{
    public function new(_parcel : String)
    {
        super('parcel "$_parcel" was not found');
    }
}

class ParcelAlreadyExistsException extends Exception
{
    public function new(_parcel : String)
    {
        super('a parcel with the name "$_parcel" already exists in this system');
    }
}

class ParcelAlreadyLoadedException extends Exception
{
    public function new(_parcel : String)
    {
        super('parcel "$_parcel" alread loaded');
    }
}

class ParcelNotAddedException extends Exception
{
    public function new(_parcel : String)
    {
        super('parcel "$_parcel" has not been added to this resource system');
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
    public function new(_resource : String, _path : String)
    {
        super('failed to load "$_resource", "$_path" does not exist');
    }
}

// #endregion

// #region event classes

/**
 * Base parcel event class. Parcel events emitted to the thread safe queue should inherit this type.
 */
private class ParcelEvent
{
    /**
     * Unique parcel ID.
     */
    public final parcel : String;

    /**
     * The type of event this will be.
     * Event type should correspond to a class inheriting this type.
     */
    public final type : ParcelEventType;

    public function new(_parcel : String, _type : ParcelEventType)
    {
        parcel = _parcel;
        type   = _type;
    }
}

private class ParcelSucceededEvent extends ParcelEvent
{
    /**
     * All the resources which were loaded and added to the system by this parcel.
     */
    public final resources : Array<Resource>;

    /**
     * Name of all the parcels this parcel depends on.
     */
    public final dependencies : Array<String>;

    public function new(_parcel : String, _type : ParcelEventType, _resources : Array<Resource>, _dependencies : Array<String>)
    {
        super(_parcel, _type);

        resources    = _resources;
        dependencies = _dependencies;
    }
}

private class ParcelProgressEvent extends ParcelEvent
{
    /**
     * Normalized value for how many items have been loaded from the parcel.
     * Pre-packed parcels count as a single item since there is no way to tell their contents before deserializing them.
     */
    public final progress : Float;

    public function new(_parcel : String, _type : ParcelEventType, _progress : Float)
    {
        super(_parcel, _type);

        progress = _progress;
    }
}

private class ParcelFailedEvent extends ParcelEvent
{
    /**
     * The exception message thrown which caused the parcel to fail loading.
     */
    public final message : String;

    public function new(_parcel : String, _type : ParcelEventType, _message : String)
    {
        super(_parcel, _type);

        message = _message;
    }
}

// #endregion
