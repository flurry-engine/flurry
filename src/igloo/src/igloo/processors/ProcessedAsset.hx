package igloo.processors;

class ProcessedAsset<T>
{
    public final name : String;

    public final data : T;

    public final response : AssetResponse;
    
    public function new(_name, _data, _response)
    {
        name     = _name;
        data     = _data;
        response = _response;
    }
}