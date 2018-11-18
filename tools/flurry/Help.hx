
import hxp.Script;
import hxp.Log;

/**
 * 
 */
class Help extends Script
{
    public function new()
    {
        super();
        
        switch (command)
        {
            case 'install':
                printInstallHelp();

            case 'build':
                printBuildHelp();

            case 'run':
                printRunHelp();

            case 'package':
                printPackageHelp();

            case _:
                printHelp();
        }
    }

    function printInstallHelp()
    {
        Log.println('Flurry 0.0.1');
        Log.println('');
        Log.println('Usage:');
        Log.println('    `flurry install [ options ]`');
        Log.println('');
        Log.println('Options:');
        Log.println('    --install-dir=[ directory ]');
        Log.println('        Override the directory to install the flurry command shortcut.');
        Log.println('');
        Log.println('    -no-sys-install');
        Log.println('        Do not install any flurry command shortcut');
        Log.println('');
        Log.println('    -no-lib-install');
        Log.println('        Do not attempt to install any haxelibs for flurry');
        Log.println('');
        Log.println('    -no-snow-install');
        Log.println('        Do not attempt to install any of the snow backend requirements');
        Log.println('');
        Log.println('    -no-kha-install');
        Log.println('        Do not attempt to install any of the kha backend requirements');
    }

    function printBuildHelp()
    {
        //
    }

    function printRunHelp()
    {
        //
    }

    function printPackageHelp()
    {
        //
    }

    function printHelp()
    {
        Log.println('Flurry 0.0.1');
        Log.println('');
        Log.println('Commands');
        Log.println('    install - Installs the dependencies and shortcuts required for flurry.');
        Log.println('    build   - Build a flurry project.');
        Log.println('    run     - Build and run a flurry project.');
        Log.println('    package - Build and package a flurry project for distribution');
        Log.println('    help    - Display detailed information on a command and all its options.');
    }
}
