package igloo.processors;

/**
 * Each call to a `IAssetProcessor<T>`'s pack function returns one of these requests.
 * It describes how the data wants to be packed and provides a means to transfer data
 * between the pack and write functions.
 */
class ResourceRequest<T>
{
    /**
     * The data provided from the processors pack function.
     * This will be passed into the write function of the same processor.
     */
    public final data : T;

    /**
     * The request generated from the processors pack function.
     */
    public final type : RequestType;

    public function new(_data, _type)
    {
        data = _data;
        type = _type;
    }
}