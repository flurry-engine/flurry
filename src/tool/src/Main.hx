package;

import tink.Cli;
import commands.Build;
import commands.Create;

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

    @:command public final build : Build;

    function new()
    {
        build = new Build();
    }

    @:defaultCommand public function help()
    {
        Console.log('Flurry');
        Console.println(Cli.getDoc(this));
    }

    @:command public function create()
    {
        switch new Create().run()
        {
            case Failure(_message):
                Sys.println('failed to create project : $_message');
                Sys.exit(1);
            case _:
                //
        }
    }
}