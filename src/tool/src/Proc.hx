import sys.io.Process;
import uk.aidanlee.flurry.api.core.Unit;
import uk.aidanlee.flurry.api.core.Result;

using Safety;

/**
 * Simple wrapper around manually creating a process, capturing its std out / error and result code.
 * Also allows process creation to be mocked for tests.
 */
class Proc
{
    public function new() { }

    public function run(_executable : String, _arguments : Array<String>, _verbose : Bool) : Result<Unit, String>
    {
        final code = if (_verbose)
                Sys.command(_executable, _arguments)
            else {
                final proc = new Process(_executable, _arguments);
                final code = proc.exitCode(true);

                proc.close();
                code;
            }

        return
            if (code == 0)
                Success(Unit.value)
            else
                Failure('$_executable exited with code $code');
    }
}