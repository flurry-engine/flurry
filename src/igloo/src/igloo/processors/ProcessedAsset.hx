package igloo.processors;

class ProcessedAsset<T>
{
    public final data : T;

    public final response : AssetResponse;
    
    public function new(_data, _response)
    {
        data     = _data;
        response = _response;
    }
}