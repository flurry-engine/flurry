package igloo.processors;

class ProcessedAsset<T>
{
    public final id : String;

    public final data : T;

    public final response : AssetResponse;
    
    public function new(_id, _data, _response)
    {
        id       = _id;
        data     = _data;
        response = _response;
    }
}