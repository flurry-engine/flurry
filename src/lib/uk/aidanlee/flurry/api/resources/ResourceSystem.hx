package uk.aidanlee.flurry.api.resources;

import rx.disposables.ISubscription;
import haxe.Exception;
import haxe.io.Path;
import haxe.ds.Vector;
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
    final parcelResources : Map<String, Array<ResourceID>>;

    /**
     * Map of all resources in this system keyed by their unique ID.
     */
    final resourceIDCache : Map<Int, Resource>;

    /**
     * Map of all resources in this system keyed by their unique name.
     */
    final resourceNameCache : Map<String, Resource>;

    /**
     * How many parcels reference each resource.
     * Prevents storing multiple of the same resource and ensures they aren't removed when still in use.
     */
    final resourceReferences : Map<Int, Int>;

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
        resourceIDCache    = [];
        resourceNameCache  = [];
        resourceReferences = [];
    }

    /**
     * Loads the provided parcels resources into the system.
     * If a parcel in the list has already been added its resources will not be added again.
     * @param _parcels List parcel files to load.
     * @return Observable of loading progress (normalised 0 - 1)
     */
    public function load(_parcels : ReadOnlyArray<String>) : IObservable<Float>
    {
        final progress = new Behavior(0.0);

        Observable
            .of_enum(cast _parcels)
            .flatMap(file -> Observable
                .create(observer -> loadParcel(file, observer))
                .subscribeOn(workScheduler)
                .observeOn(syncScheduler))
            .map(v -> {
                if (!parcelResources.exists(v.parcel))
                {
                    parcelResources[v.parcel] = [];
                }

                addResource(v.resource);

                parcelResources[v.parcel].unsafe().push(v.resource.id);

                v.progress;
            })
            .scan(0.0, (_acc, _next) -> _acc + (_next / _parcels.length))
            .subscribe(progress);

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
                if (resourceIDCache.exists(res))
                {
                    removeResource(resourceIDCache[res].unsafe());
                }
            }

            parcelResources.remove(_name);
        }
    }

    /**
     * Add a resource to this system.
     * If the resource has already been added to this system the reference count is increased by one.
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

            resourceIDCache[_resource.id] = _resource;
            resourceNameCache[_resource.name] = _resource;

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
        if (resourceReferences.exists(_resource.id))
        {
            final referenceCount = resourceReferences[_resource.id].unsafe();
            if (referenceCount == 1)
            {
                if (resourceIDCache.exists(_resource.id))
                {
                    final toRemove = resourceIDCache[_resource.id].unsafe();

                    resourceIDCache.remove(_resource.id);
                    resourceNameCache.remove(_resource.name);

                    events.removed.onNext(toRemove);
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
     * Retrieve a resource from the system based on its unique string name.
     * @param _name Name of the resource.
     * @param _type Class type of the resource.
     * @return Resource object.
     * @throws InvalidResourceTypeException If the resource cannot be cast to the specified resource class.
     * @throws ResourceNotFoundException If a resource with the provided name is not in the system.
     */
    public function getByName<T : Resource>(_name : String, _type : Class<T>) : T
    {
        if (resourceNameCache.exists(_name))
        {
            final res = resourceNameCache[_name].unsafe();
            final obj = Std.downcast(res, _type);
            
            if (obj != null)
            {
                return obj;
            }

            throw new InvalidResourceTypeException(_name, Type.getClassName(_type));
        }
        
        throw new ResourceNotFoundException(_name);
    }

    /**
     * Retrieve a resource from the system based on its unique ID.
     * @param _id ID of the resource.
     * @param _type Class type of the resource.
     * @return Resource object.
     * @throws InvalidResourceTypeException If the resource cannot be cast to the specified resource class.
     * @throws ResourceNotFoundException If a resource with the provided ID is not in the system.
     */
    public function getByID<T : Resource>(_id : ResourceID, _type : Class<T>) : T
    {
        if (resourceIDCache.exists(_id))
        {
            final res = resourceIDCache[_id].unsafe();
            final obj = Std.downcast(res, _type);
            
            if (obj != null)
            {
                return obj;
            }

            throw new InvalidResourceTypeException(Std.string(_id), Type.getClassName(_type));
        }
        
        throw new ResourceNotFoundException(Std.string(_id));
    }

    /**
     * Loads a parcel and passes events into the observer.
     * @param _file Parcel file to open. Should be relative to the projects parcel directory (`assets/parcels`).
     * @param _observer Observer to pump events into.
     * @return If the parcel was successfully loaded.
     */
    function loadParcel(_file : String, _observer : IObserver<ParcelLoadingEvent>) : ISubscription
    {
        final path = Path.join([ 'assets', 'parcels', _file ]);

        if (!fileSystem.file.exists(path))
        {
            _observer.onError('failed to load "${_file}", "${path}" does not exist');

            return Subscription.empty();
        }

        // TODO : Should probably progress by 1 as overall load tracking will be off.
        if (parcelResources.exists(_file))
        {
            _observer.onCompleted();

            return Subscription.empty();
        }

        final reader = new ParcelInput(fileSystem.file.read(path));
        
        switch reader.readHeader()
        {
            case Success(header):
                for (_ in 0...header.assets)
                {
                    switch reader.readAsset()
                    {
                        case Success(asset):
                            _observer.onNext({
                                parcel   : _file,
                                resource : asset,
                                progress : 1 / header.assets
                            });
                        case Failure(reason):
                            _observer.onError(reason);
        
                            reader.close();
        
                            return Subscription.empty();
                    }
                }
            case Failure(reason):
                _observer.onError(reason);

                reader.close();

                return Subscription.empty();
        }

        _observer.onCompleted();

        reader.close();

        return Subscription.empty();
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

@:structInit @:publicFields class ParcelLoadingEvent
{
    final parcel : String;

    final resource : Resource;

    final progress : Float;
}