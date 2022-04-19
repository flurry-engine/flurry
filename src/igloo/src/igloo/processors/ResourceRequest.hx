package igloo.processors;

import haxe.ds.Option;
import igloo.utils.OneOf;

/**
 * Each call to a `IAssetProcessor<T>`'s pack function returns 1..N of these requests.
 * Resources are assigned a unique ID and have a string name. Each request can also pack 0..N images into the parcel atlas.
 */
class ResourceRequest<T>
{
    /**
     * Name of the resource.
     */
    public final name : String;

    /**
     * The data provided from the processors pack function.
     * This will be passed into the write function of the same processor.
     */
    public final data : T;

    /**
     * The images this resource wants to pack.
     */
    public final packs : Option<OneOf<RequestType, Array<RequestType>>>;

    public function new(_name, _data, _packs)
    {
        name  = _name;
        data  = _data;
        packs = _packs;
    }
}