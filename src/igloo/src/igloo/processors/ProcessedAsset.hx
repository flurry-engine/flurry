package igloo.processors;

class ProcessedAsset<T>
{
    public final id : String;

    public final data : T;

    public final response : AssetResponse;

    /**
     * The byte position of this asset in the output parcel stream.
     */
    public var position : Int;

    /**
     * The number of bytes this asset takes up in the output parcel stream.
     */
    public var length : Int;
    
    public function new(_id, _data, _response)
    {
        id       = _id;
        data     = _data;
        response = _response;
        position = 0;
        length   = 0;
    }
}