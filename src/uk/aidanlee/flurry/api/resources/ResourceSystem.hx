package uk.aidanlee.flurry.api.resources;

import rx.subjects.Replay;
import uk.aidanlee.flurry.api.resources.Resource;
import rx.schedulers.MakeScheduler;
import rx.subjects.Behavior;
import rx.observers.IObserver;
import rx.Subscription;
import haxe.Exception;
import haxe.Unserializer;
import haxe.io.Path;
import haxe.zip.Uncompress;
import format.png.Tools;
import format.png.Reader;
import json2object.JsonParser;
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
     * The scheduler that will load the parcels.
     */
    final workScheduler : MakeScheduler;

    /**
     * The scheduler that will run all observers.
     * This should be set to a main thread scheduler if `workScheduler` will perform the subscribe function on a separate thread.
     */
    final syncScheduler : MakeScheduler;

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
     * All resources stored in this system, keyed by their name.
     */
    final resourceCache : Map<String, Resource>;

    /**
     * How many parcels reference each resource.
     * Prevents storing multiple of the same resource and ensures they aren't removed when still in use.
     */
    final resourceReferences : Map<String, Int>;

    /**
     * Creates a new resources system.
     * Allows the creation and loading of parcels and caching their resources.
     */
    public function new(_events : ResourceEvents, _fileSystem : IFileSystem, _workScheduler : MakeScheduler, _syncScheduler : MakeScheduler)
    {
        events             = _events;
        fileSystem         = _fileSystem;
        workScheduler      = _workScheduler;
        syncScheduler      = _syncScheduler;
        parcelResources    = [];
        parcelDependencies = [];
        resourceCache      = [];
        resourceReferences = [];
    }

    public function load(_parcel : ParcelType) : Observable<Float>
    {
        final name = switch _parcel {
            case Definition(_name, _) : _name;
            case PrePackaged(_name) : _name;
        }

        if (parcelResources.exists(name))
        {
            return Observable.empty();
        }
        else
        {
            final replay   = Replay.create();
            final progress = Behavior.create(0.0);

            Observable
                .create((_observer : IObserver<ParcelEvent>) -> {
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
                .subscribeOn(workScheduler)
                .observeOn(syncScheduler)
                .subscribe(replay);

            replay.subscribeFunction(
                    _event -> {
                        switch _event
                        {
                            case Progress(_progress, _resource):
                                addResource(_resource);
                                progress.onNext(_progress);
                            case List(_name, _list):
                                parcelResources[_name] = _list;
                            case Dependency(_name, _depends):
                                parcelDependencies[_name] = _depends;
                        }
                    },
                    progress.onError,
                    progress.onCompleted
                );
    
            return progress;
        }
    }

    public function free(_name : String)
    {
        if (parcelDependencies.exists(_name))
        {
            for (dep in parcelDependencies[_name].unsafe())
            {
                free(dep);
            }

            parcelDependencies.remove(_name);
        }

        if (parcelResources.exists(_name))
        {
            for (res in parcelResources[_name].unsafe())
            {
                if (resourceCache.exists(res))
                {
                    removeResource(resourceCache[res].unsafe());
                }
            }

            parcelResources.remove(_name);
        }
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
            resourceReferences[_resource.id] = 1;

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
        
        throw new ResourceNotFoundException(_id);
    }

    /**
     * Loads all the the resources in the list of a different thread.
     * @param _name Parcel unique ID
     * @param _list List of resources to load.
     */
    function loadDefinition(_name : String, _list : ParcelList, _observer : IObserver<ParcelEvent>)
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
                Progress(
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
                Progress(
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
                Progress(
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

            final parser = new JsonParser<ShaderInfoLayout>();
            parser.fromJson(fileSystem.file.getText(asset.path));

            for (error in parser.errors)
            {
                throw error;
            }

            final layout = new ShaderLayout(
                parser.value.textures,
                [
                    for (b in parser.value.blocks) new ShaderBlock(b.name, b.binding, [
                        for (v in b.values) new ShaderValue(v.name, v.type)
                    ])
                ]);
            final sourceOGL3 = asset.ogl3 == null ? null : new ShaderSource(
                asset.ogl3.compiled.or(false),
                fileSystem.file.getBytes(asset.ogl3.vertex),
                fileSystem.file.getBytes(asset.ogl3.fragment));
            final sourceOGL4 = asset.ogl4 == null ? null : new ShaderSource(
                asset.ogl4.compiled.or(false),
                fileSystem.file.getBytes(asset.ogl4.vertex),
                fileSystem.file.getBytes(asset.ogl4.fragment)
            );
            final sourceHLSL = asset.hlsl == null ? null : new ShaderSource(
                asset.hlsl.compiled.or(false),
                fileSystem.file.getBytes(asset.hlsl.vertex),
                fileSystem.file.getBytes(asset.hlsl.fragment)
            );

            _observer.onNext(
                Progress(
                    ++loadedIndices / totalResources,
                    new ShaderResource(asset.id, layout, sourceOGL3, sourceOGL4, sourceHLSL)
                )
            );
        }

        _observer.onNext(List(_name, flattenParcelList(_list)));
    }

    /**
     * Load a pre-packaged parcel from the disk.
     * @param _file Parcel file name.
     */
    function loadPrePackaged(_file : String, _observer : IObserver<ParcelEvent>)
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

        if (parcel == null)
        {
            _observer.onError('unable to cast deserialised bytes to a ParcelResource');

            return;
        }

        if (parcel.depends.length > 0)
        {
            _observer.onNext(Dependency(_file, parcel.depends));

            for (dependency in parcel.depends)
            {
                loadPrePackaged(dependency, _observer);
            }   
        }

        for (i in 0...parcel.assets.length)
        {
            _observer.onNext(
                Progress(
                    i / parcel.assets.length,
                    parcel.assets[i]
                )
            );
        }

        _observer.onNext(List(_file, [ for (res in parcel.assets) res.id ]));
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

    function flattenParcelList(_list : ParcelList) : Array<String>
    {
        final list = [];

        for (res in _list.bytes)
            list.push(res.id);
        for (res in _list.images)
            list.push(res.id);
        for (res in _list.shaders)
            list.push(res.id);
        for (res in _list.texts)
            list.push(res.id);

        return list;
    }
}

// #region exceptions

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

// #endregion

// #region event classes

private enum ParcelEvent
{
    Progress(_progress : Float, _resource : Resource);
    List(_name : String, _list : Array<String>);
    Dependency(_name : String, _dependencies : Array<String>);
}


// #endregion
