package uk.aidanlee.resources;

import hx.concurrent.event.SyncEventDispatcher;
import haxe.Json;
import snow.api.Debug.def;
import snow.api.buffers.Uint8Array;
import hx.concurrent.collection.Queue;
import hx.concurrent.executor.Executor;
import uk.aidanlee.resources.Parcel.ParcelList;
import uk.aidanlee.resources.Parcel.ShaderInfo;
import uk.aidanlee.resources.Parcel.ImageInfo;
import uk.aidanlee.resources.Parcel.JSONInfo;
import uk.aidanlee.resources.Parcel.TextInfo;
import uk.aidanlee.resources.Parcel.BytesInfo;
import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.resources.Resource.ImageResource;
import uk.aidanlee.resources.Resource.JSONResource;
import uk.aidanlee.resources.Resource.TextResource;
import uk.aidanlee.resources.Resource.BytesResource;

typedef ParcelResult = {
    var id : String;
    var resources : Array<Resource>;
}

class ResourceSystem
{
    /**
     * All parcels loaded in this resource system.
     */
    public final parcels : Map<String, Parcel>;

    /**
     * Map of all loaded resources by their ID.
     */
    final cache : Map<String, Resource>;

    /**
     * Thread pool to load parcels without blocking the main thread.
     */
    final executor : Executor;

    /**
     * Async event queue so the main thread can be notified when a parcel has been loaded.
     * Main thread then adds the loaded resources to the cache. Removes the need for any manual locking on the cache map.
     */
    final queue : Queue<ParcelResult>;

    /**
     * Creates a new resources system.
     * Allows the creation and loading of parcels and caching their resources.
     * 
     * @param _threads Number of active threads for loading parcels (defaults 1).
     */
    public function new(_threads : Int = 1)
    {
        parcels  = new Map();
        cache    = new Map();
        executor = Executor.create(_threads);
        queue    = new Queue();
    }

    /**
     * Create a new parcel in this system.
     * @param _name Unique name of the parcel.
     * @param _list List of all of this parcels resources.
     * @return Parcel
     */
    public function createParcel(_name : String, _list : ParcelList, _onLoaded : Array<Resource>->Void) : Parcel
    {
        return new Parcel(this, _name, _list, _onLoaded);
    }

    /**
     * Load a parcels resources and add them to the system.
     * @param _parcel Parcel name to load.
     */
    public function load(_parcel : String)
    {
        var parcel = parcels.get(_parcel);

        /**
         * This function is ran in a seperate thread to load all the assets without blocking the main thread.
         * An event is fired with the loaded resources and parcel ID so the main thread can add them.
         */
        var parcelLoader = function() {

            var resources = new Array<Resource>();
            
            var assets : Array<BytesInfo> = def(parcel.list.bytes, []);
            for (asset in assets)
            {
                resources.push(new BytesResource(asset.id, sys.io.File.getBytes(asset.id)));
            }

            var assets : Array<TextInfo> = def(parcel.list.texts, []);
            for (asset in assets)
            {
                resources.push(new TextResource(asset.id, sys.io.File.getContent(asset.id)));
            }

            var assets : Array<JSONInfo> = def(parcel.list.jsons, []);
            for (asset in assets)
            {
                resources.push(new JSONResource(asset.id, Json.parse(sys.io.File.getContent(asset.id))));
            }

            var assets : Array<ImageInfo> = def(parcel.list.images, []);
            for (asset in assets)
            {
                var bytes = sys.io.File.getBytes(asset.id);
                var info  = stb.Image.load_from_memory(bytes.getData(), bytes.length, 4);

                resources.push(new ImageResource(asset.id, info.w, info.h, Uint8Array.fromBuffer(info.bytes, 0, info.bytes.length)));
            }

            var assets : Array<ShaderInfo> = def(parcel.list.shaders, []);
            for (asset in assets)
            {
                var layout = Json.parse(sys.io.File.getContent(asset.id));
                var sourceWebGL = asset.webgl == null ? null : { vertex : sys.io.File.getContent(asset.webgl.vertex), fragment : sys.io.File.getContent(asset.webgl.fragment) };
                var sourceGL45  = asset.gl45  == null ? null : { vertex : sys.io.File.getContent(asset.gl45.vertex) , fragment : sys.io.File.getContent(asset.gl45.fragment) };
                var sourceHLSL  = asset.hlsl  == null ? null : { vertex : sys.io.File.getContent(asset.hlsl.vertex) , fragment : sys.io.File.getContent(asset.hlsl.fragment) };

                resources.push(new ShaderResource(asset.id, layout, sourceWebGL, sourceGL45, sourceHLSL));
            }

            queue.push({ id : _parcel, resources : resources });
        }

        executor.submit(parcelLoader);
    }

    /**
     * Frees the resources used by a parcel.
     * Resources are reference counted so if multiple parcels depend on an asset it won't be removed until all parcels are freed.
     * @param _parcel Name of the parcel to free.
     */
    public function free(_parcel : String)
    {
        //
    }

    /**
     * Get a loaded resource from this system.
     * @param _id   ID of the resource.
     * @param _type Class type of the resource.
     * @return T
     */
    public function get<T>(_id : String, _type : Class<T>) : T
    {
        return cast cache.get(_id);
    }

    /**
     * [Description]
     */
    public function update()
    {
        var event = queue.pop();
        while (event != null)
        {
            for (resource in event.resources)
            {
                cache.set(resource.id, resource);
            }

            parcels.get(event.id).onLoaded(event.resources);

            event = queue.pop();
        }
    }
}
