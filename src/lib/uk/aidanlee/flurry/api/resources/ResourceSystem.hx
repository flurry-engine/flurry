package uk.aidanlee.flurry.api.resources;

import haxe.Exception;
import haxe.io.Path;
import haxe.ds.ReadOnlyArray;
import rx.Subscription;
import rx.subjects.Behavior;
import rx.observers.IObserver;
import rx.schedulers.IScheduler;
import rx.observables.IObservable;
import sys.io.abstractions.IFileSystem;
import uk.aidanlee.flurry.api.stream.ParcelInput;
import uk.aidanlee.flurry.api.resources.Resource;

using Safety;
using rx.Observable;

@:nullSafety(Loose) class ResourceSystem
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
    final workScheduler : IScheduler;

    /**
     * The scheduler that will run all observers.
     * This should be set to a main thread scheduler if `workScheduler` will execute the subscribe function on a separate thread.
     */
    final syncScheduler : IScheduler;

    /**
     * Map of a parcels ID to all the resources IDs contained within it.
     * Stored since the parcel could be modified by the user and theres no way to know whats inside a pre-packed parcel until its unpacked.
     */
    final parcelResources : Map<String, Array<String>>;

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
    public function new(_events : ResourceEvents, _fileSystem : IFileSystem, _workScheduler : IScheduler, _syncScheduler : IScheduler)
    {
        events             = _events;
        fileSystem         = _fileSystem;
        workScheduler      = _workScheduler;
        syncScheduler      = _syncScheduler;
        parcelResources    = [];
        resourceCache      = [];
        resourceReferences = [];
    }

    /**
     * Loads the provided parcels resources into the system.
     * If the parcel has already been loaded an empty observable is returned.
     * @param _parcels List parcel files to load.
     * @return Observable<Float> Observable of loading progress (normalised 0 - 1)
     */
    public function load(_parcels : ReadOnlyArray<String>) : IObservable<Float>
    {
        final progress = new Behavior(0.0);

        // This observable performs the loading work.
        // It subscribes on the work scheduler and observable functions are called on the sync scheduler.
        // These are probably some sort of thread pool and them main app thread.
        // We manually track if the loading was successful otherwise we could fire onError and onComplete events.
        // We also recursivly call `loadPrePackaged` for dependencies which could fire onComplete before all resources have loaded.
        Observable
            .create((_observer : IObserver<ParcelEvent>) -> {
                for (i => path in _parcels)
                {
                    if (!loadParcel(path, i, _parcels.length, _observer))
                    {
                        break;
                    }
                }

                _observer.onCompleted();

                return Subscription.empty();
            })
            .subscribeOn(workScheduler)
            .observeOn(syncScheduler)
            .subscribeFunction(
                _v -> {
                    switch _v
                    {
                        case Resource(_resource):
                            addResource(_resource);
                        case Progress(_time):
                            progress.onNext(_time);
                        case List(_name, _list):
                            parcelResources[_name] = _list;
                    }
                },
                progress.onError,
                progress.onCompleted
            );

        return progress;
    }

    /**
     * Free a parcel and its resources from the system.
     * @param _name Parcel name.
     */
    public function free(_name : String)
    {
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

            events.created.onNext(_resource);
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
                    events.removed.onNext(resourceCache[_resource.id].unsafe());
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

    function loadParcel(_file : String, _index : Int, _max : Int, _observer : IObserver<ParcelEvent>) : Bool
    {
        final path = Path.join([ 'assets', 'parcels', _file ]);

        if (!fileSystem.file.exists(path))
        {
            _observer.onError('failed to load "${_file}", "${path}" does not exist');

            return false;
        }

        // If the parcel has already been loaded immediately progress by the max amount for a parcel segment.
        if (parcelResources.exists(_file))
        {
            final segment  = 1 / _max;
            final nextBase = (_index + 1) * segment;

            _observer.onNext(Progress(nextBase));

            return true;
        }

        final reader = new ParcelInput(fileSystem.file.read(path));

        return switch reader.read()
        {
            case Success(_assets):
                for (i => asset in _assets)
                {
                    final segment = 1 / _max;
                    final current = (_index * segment) + ((i / _assets.length) / _max);

                    _observer.onNext(Resource(asset));
                    _observer.onNext(Progress(current));
                }

                _observer.onNext(List(_file, [ for (res in _assets) res.id ]));

                reader.close();

                true;
            case Failure(_message):
                _observer.onError(_message);

                reader.close();

                false;
        }
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
    Resource(_resource : Resource);
    List(_name : String, _list : Array<String>);
    Progress(_value : Float);
}


// #endregion
