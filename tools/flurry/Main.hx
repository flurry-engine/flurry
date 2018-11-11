package;

import hxp.Haxelib;
import hxp.Path;
import hxp.System;
import hxp.Log;

class Main
{
    static function main()
    {
        var path      = Sys.args()[0];
        var command   = '';
        var arguments = [];

        Log.info ("", Log.accentColor + "Executing script: " + path + Log.resetColor);
		
		var dir = Path.directory (path);
		var file = Path.withoutDirectory (path);
		var className = Path.withoutExtension (file);
		className = className.substr (0, 1).toUpperCase () + className.substr (1);
		
		var version = "0.0.0";
		var buildArgs = [ className, "-main", "hxp.Script", "-D", "hxp="+ version, "-cp", Path.combine (Haxelib.getPath (new Haxelib ("hxp")), "src"), "-cp", "/media/aidan/archive/programming/haxe/flurry/engine/src" ];
		var runArgs = [ (command == null || command == "") ? "default" : command ];
		runArgs = runArgs.concat (arguments);
		
		if (Log.verbose) runArgs.push ("-verbose");
		if (!Log.enableColor) runArgs.push ("-nocolor");
		
		runArgs.push (className);
		runArgs.push (Sys.getCwd ());
		
        System.runScript (path, buildArgs, runArgs, dir);
    }
}
