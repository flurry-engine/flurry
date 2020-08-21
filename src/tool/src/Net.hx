import haxe.io.Bytes;
import uk.aidanlee.flurry.api.core.Result;

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

    public function download(_url : String, _proc : Proc) : Result<Bytes, String>
    {
        var res  = Failure('');
        var code = 0;

        final request = new haxe.Http(_url);
        request.onStatus = data -> code = data;
        request.onError  = data -> res  = Failure(data);
        request.onBytes  = function(data) {
            switch code
            {
                case 200: res = Success(data);
                case 302:
                    // Github returns redirects as <html><body><a href="redirect url"></body></html>

                    final access = new haxe.xml.Access(Xml.parse(data.toString()).firstElement());
                    final redir  = access.node.body.node.a.att.href;

                    res = download(redir, _proc);
                case other: res = Failure('Unexpected http status : $other');
            }
        }
        request.request();

        return res;
    }
}
