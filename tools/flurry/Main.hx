package;

import sys.FileSystem;
import hxp.Haxelib;
import hxp.Path;
import hxp.System;
import hxp.Log;

class Main
{
	static function main()
	{
		new Main();
	}

	/**
	 * The command line arguments passed when this program was ran.
	 * The first argument will be cut off to identify which sub script to run.
	 */
	final arguments : Array<String>;

	public function new()
	{
		arguments = Sys.args();

		// When the tool is ran from haxelib the CWD is the root directory of the haxelib.
		// Haxelib also appends the CWD where it was called from as a last argument and sets the 'HAXELIB_RUN' env.
		// So if we are running in haxelib mode set the CWD to the last cli argument.
		if (Sys.getEnv('HAXELIB_RUN') == '1')
		{
			Sys.setCwd(arguments.pop());
		}

		if (arguments.length == 0)
		{
			doHelpCommand();
		}

		switch(arguments.shift())
		{
			case 'install':
				doInstallCommand();

			case 'build':
				doBuildCommand('build');

			case 'run':
				doBuildCommand('run');

			case 'package':
				doBuildCommand('package');

			case 'clean':
				doBuildCommand('clean');

			case 'help':
				doHelpCommand();

			case _:
				doHelpCommand();
		}
	}

	/**
	 * The install command ensures all the correct haxelibs are installed and puts the flurry tool in a user or system directory.
	 */
	function doInstallCommand()
	{
		runHxpScript(Path.join([ Haxelib.getPath(new Haxelib("Flurry")), 'tools', 'flurry', 'Install.hx' ]));
	}

	/**
	 * Run the build script with a command.
	 * @param _command The command for the build script to decide what to do.
	 */
	function doBuildCommand(_command : String)
	{
		var script  = findBuildScript();
		if (script != '')
		{
			runHxpScript(script, _command);
		}
		else
		{
			Log.println('Cound not find a suitable script file to build');
		}
	}

	/**
	 * Prints help about the entire tool or a specific command.
	 */
	function doHelpCommand()
	{
		var script  = Path.join([ Haxelib.getPath(new Haxelib("Flurry")), 'tools', 'flurry', 'Help.hx' ]);
		var command = arguments.length == 0 ? 'default' : arguments.shift();

		runHxpScript(script, command);
	}

	/**
	 * Run a .hxp script with the correct flurry classes imported.
	 * @param _script Script file to run.
	 * @param _command Optional command for the script.
	 */
	function runHxpScript(_script : String, _command : String = '')
	{	
		var file      = Path.withoutDirectory(_script);
		var directory = Path.directory(_script);
		var className = Path.withoutExtension(file);
		className = className.substr(0, 1).toUpperCase() + className.substr(1);
		
		var version   = "1.0.5";
		var buildArgs = [
			className,
			"-main", "hxp.Script",
			"-D"   , "hxp=" + version,
			"-L"   , "hxp",
			"-cp"  , Path.join([ Haxelib.getPath(new Haxelib("Flurry")), 'tools', 'flurry' ])
		];
		var runArgs = [ _command == '' ? 'default' : _command ].concat(arguments);
		
		runArgs.push(className);
		runArgs.push(Sys.getCwd());
		
        System.runScript(_script, buildArgs, runArgs, directory);
	}

	/**
	 * will look for a build script in the following order.
	 * - If there is a file which matches the first argument, use that.
	 * - If there is a file called build.hxp, use that.
	 * - If there is a file called build.hx, use that.
	 * - If none of the above are found, error out.
	 * @return Script file name or empty string.
	 */
	function findBuildScript() : String
	{
		if (arguments.length > 0 && FileSystem.exists(arguments[0]))
		{
			return arguments.shift();
		}

		if (FileSystem.exists('build.hxp'))
		{
			return 'build.hxp';
		}

		if (FileSystem.exists('build.hx'))
		{
			return 'build.hx';
		}

		return '';
	}
}
