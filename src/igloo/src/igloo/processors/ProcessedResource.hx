package igloo.processors;

import haxe.ds.Option;
import igloo.utils.OneOf;

class ProcessedResource<T>
{
    public final source : String;

    public final name : String;

    public final id : Int;

    public final data : T;

    public final response : Option<OneOf<PackedResource, Array<PackedResource>>>;
    
    public function new(_source, _name, _id, _data, _response)
    {
        source   = _source;
        name     = _name;
        id       = _id;
        data     = _data;
        response = _response;
    }
}