package;

import tink.Cli;
import commands.Build;
import commands.Create;
import uk.aidanlee.flurry.api.core.Log;

using Safety;
using Utils;

class Main
{
    static function main()
    {
        // When the tool is ran from haxelib the CWD is the root directory of the haxelib.
		// Haxelib also appends the CWD where it was called from as a last argument and sets the 'HAXELIB_RUN' env.
		// So if we are running in haxelib mode set the CWD to the last cli argument.
		if (Sys.getEnv('HAXELIB_RUN') == '1')
        {
            final args = Sys.args();
            final cwd  = args.pop();

            if (cwd != null)
            {
                Sys.setCwd(cwd);
            }
        }

        Cli.process(Sys.args(), new Main()).handle(Cli.exit);
    }

    function new()
    {
        build  = new Build();
        create = new Create();
    }

    /**
     * Build a project defined in a flurry json file.
     */
    @:command public final build : Build;

    /**
     * Create a base flurry project.
     */
    @:command public final create : Create;

    /**
     * This tool is responsible for creating, building, running, and distributing flurry projects defined in a json file.
     * Calling each command with help after it will display detailed information on each option.
     * e.g. `flurry build help`.
     */
    @:defaultCommand public function help()
    {
        Log.log('Flurry', Success);
        Log.log(Cli.getDoc(this), Info);
    }
}