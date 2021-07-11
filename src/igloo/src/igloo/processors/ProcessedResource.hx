package igloo.processors;

class ProcessedResource<T>
{
    public final source : String;

    public final data : T;

    public final response : AssetResponse;
    
    public function new(_source, _data, _response)
    {
        source   = _source;
        data     = _data;
        response = _response;
    }
}