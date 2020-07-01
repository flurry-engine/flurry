import uk.aidanlee.flurry.api.core.Unit;
import uk.aidanlee.flurry.api.core.Result;

using Safety;

/**
 * Simple wrapper around manually creating a process, capturing its std out / error and result code.
 * Also allows process creation to be mocked for tests.
 */
class Proc
{
    public function new()
    {
        //
    }

    public function run(_executable : String, _arguments : Array<String> = null) : Result<Unit, String>
    {
        final code = Sys.command(_executable, _arguments);

        return
            if (code == 0)
                Success(Unit.value)
            else
                Failure('$_executable exited with code $code');
    }
}