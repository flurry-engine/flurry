import Types.Result;
import haxe.io.Bytes;
import com.akifox.asynchttp.HttpRequest;

/**
 * Simple wrapper around a http get request.
 * Allows network activity to be mocked out in tests.
 */
class Net
{
    public function new()
    {
        //
    }

    public function download(_url : String, _proc : Proc) : Result<Bytes>
    {
        var res = Failure('');

        new HttpRequest({
            async : false,
            url   : _url,
            callback      : success -> res = Success(success.contentRaw),
            callbackError : error -> res = Failure(error.error)
        }).send();

        return res;
    }
}