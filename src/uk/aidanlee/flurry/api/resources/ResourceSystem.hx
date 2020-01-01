package uk.aidanlee.flurry.api.resources;

import rx.subjects.Behavior;
import rx.subjects.Replay;
import rx.observers.IObserver;
import rx.Subscription;
import rx.observables.IObservable;
import haxe.Exception;
import haxe.Unserializer;
import haxe.io.Path;
import haxe.zip.Uncompress;
import format.png.Tools;
import format.png.Reader;
import json2object.JsonParser;
import uk.aidanlee.flurry.api.schedulers.ThreadPoolScheduler;
import uk.aidanlee.flurry.api.schedulers.MainThreadScheduler;
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
using rx.Observable;

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
     * Creates a new resources system.
     * Allows the creation and loading of parcels and caching their resources.
     * 
     * @param _threads Number of active threads for loading parcels (defaults 1).
     */
    public function new(_events : ResourceEvents, _fileSystem : IFileSystem, _threads : Int = 1)
    {
        events             = _events;
        fileSystem         = _fileSystem;
        parcelResources    = [];
        parcelDependencies = [];
        resourceCache      = [];
        resourceReferences = [];
    }

    /**
     * Load the provided parcel.
     * @param _parcel The parcel to load.
     * @throws ParcelAlreadyLoadedException When this parcel has already been loaded.
     * @throws ParcelNotAddedException When the provided parcel is not tracked by the system.
     */
    public function load(_parcel : ParcelType) : Observable<Float>
    {
        final replay   = Replay.create();
        final progress = Behavior.create(0.0);

        Observable
            .create((_observer : IObserver<ParcelProgressEvent>) -> {
                switch _parcel
                {
                    case Definition(_name, _definition):
                        loadDefinition(_name, _definition, _observer);
                    case PrePackaged(_name):
                        loadPrePackaged(_name, _observer);
                }

                _observer.onCompleted();

                return Subscription.empty();
            })
            .subscribeOn(ThreadPoolScheduler.current)
            .observeOn(MainThreadScheduler.current)
            .subscribeFunction(
                _v -> replay.onNext(_v),
                _e -> replay.onError(_e),
                () -> replay.onCompleted()
            );

        // Internal observer which collects all the progress events and once loading has finished adds them all to the system.
        replay.collect().subscribeFunction(
            _events -> {
                final newResources = [];
                final name = switch _parcel {
                    case Definition(_name, _) : _name;
                    case PrePackaged(_name) : _name;
                }

                for (event in _events)
                {
                    newResources.push(event.resource.id);

                    addResource(event.resource);
                }

                parcelResources[name] = newResources;
                parcelDependencies[name] = [];
            }
        );

        // Behaviour subject which will collect just the progress values from the main observer events
        replay.subscribeFunction(
            _v -> progress.onNext(_v.progress),
            _e -> progress.onError(_e),
            () -> progress.onCompleted()
        );

        return progress;
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
     * Loads all the the resources in the list of a different thread.
     * @param _name Parcel unique ID
     * @param _list List of resources to load.
     */
    function loadDefinition(_name : String, _list : ParcelList, _observer : IObserver<ParcelProgressEvent>)
    {
        final totalResources = calculateTotalResources(_list);

        var loadedIndices  = 0;

        for (asset in _list.bytes)
        {
            if (!fileSystem.file.exists(asset.path))
            {
                _observer.onError('failed to load "${asset.id}", "${asset.path}" does not exist');

                return;
            }

            _observer.onNext(
                new ParcelProgressEvent(
                    ++loadedIndices / totalResources,
                    new BytesResource(asset.id, fileSystem.file.getBytes(asset.path))
                )
            );
        }

        for (asset in _list.texts)
        {
            if (!fileSystem.file.exists(asset.path))
            {
                _observer.onError('failed to load "${asset.id}", "${asset.path}" does not exist');

                return;
            }

            _observer.onNext(
                new ParcelProgressEvent(
                    ++loadedIndices / totalResources,
                    new TextResource(asset.id, fileSystem.file.getText(asset.path))
                )
            );
        }

        for (asset in _list.images)
        {
            if (!fileSystem.file.exists(asset.path))
            {
                _observer.onError('failed to load "${asset.id}", "${asset.path}" does not exist');

                return;
            }

            var info = new Reader(fileSystem.file.read(asset.path)).read();
            var head = Tools.getHeader(info);

            _observer.onNext(
                new ParcelProgressEvent(
                    ++loadedIndices / totalResources,
                    new ImageResource(asset.id, head.width, head.height, Tools.extract32(info))
                )
            );
        }

        for (asset in _list.shaders)
        {
            if (!fileSystem.file.exists(asset.path))
            {
                _observer.onError('failed to load "${asset.id}", "${asset.path}" does not exist');

                return;
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

            _observer.onNext(
                new ParcelProgressEvent(
                    ++loadedIndices / totalResources,
                    new ShaderResource(asset.id, layout, sourceOGL3, sourceOGL4, sourceHLSL)
                )
            );
        }

        _observer.onCompleted();
    }

    /**
     * Load a pre-packaged parcel from the disk.
     * @param _file Parcel file name.
     */
    function loadPrePackaged(_file : String, _observer : IObserver<ParcelProgressEvent>)
    {
        final path = Path.join([ 'assets', 'parcels', _file ]);

        if (!fileSystem.file.exists(path))
        {
            _observer.onError('failed to load "${_file}", "${path}" does not exist');

            return;
        }

        final bytes  = Uncompress.run(fileSystem.file.getBytes(path));
        final loader = new Unserializer(bytes.toString());
        final parcel = (cast loader.unserialize() : ParcelResource);

        for (dependency in parcel.depends)
        {
            loadPrePackaged(dependency, _observer);
        }

        for (i in 0...parcel.assets.length)
        {
            _observer.onNext(
                new ParcelProgressEvent(
                    i / parcel.assets.length,
                    parcel.assets[i]
                )
            );
        }
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

private class ParcelProgressEvent
{
    /**
     * Normalized value for how many items have been loaded from the parcel.
     * Pre-packed parcels count as a single item since there is no way to tell their contents before deserializing them.
     */
    public final progress : Float;

    public final resource : Resource;

    public function new(_progress : Float, _resource : Resource)
    {
        progress = _progress;
        resource = _resource;
    }
}

// #endregion
