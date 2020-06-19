package;

import sys.io.File;
import sys.io.abstractions.concrete.FileSystem;
import tink.Cli;
import tink.Json;
import Types.Project;
import commands.*;

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

    /**
     * Path to the json build file.
     * default : build.json
     */
    @:flag('file')
    @:alias('f')
    public var buildFile : String;

    /**
     * If set the project will not be re-built before being ran or packaged.
     * default : false
     */
    @:flag('no-build')
    @:alias('n')
    public var noBuild : Bool;

    /**
     * If set the project will not be restored before built.
     * default : false
     */
    @:flag('no-restore')
    @:alias('i')
    public var noRestore : Bool;

    /**
     * If set the build directory will be delected before building.
     * default : false
     */
    @:flag('clean')
    @:alias('c')
    public var clean : Bool;

    /**
     * If set this will build in release mode regardless of the build files profile.
     * default : false
     */
    @:flag('release')
    @:alias('r')
    public var release : Bool;

    public function new()
    {
        buildFile = 'build.json';
        noBuild   = false;
        noRestore = false;
        clean     = false;
        release   = false;
    }

    @:defaultCommand public function help()
    {
        Sys.println(Cli.getDoc(this));
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

    @:command public function build()
    {
        final project = parseProject();

        if (!noRestore)
        {
            switch new Restore(project).run()
            {
                case Failure(_message):
                    Sys.println('failed to restore project $buildFile : $_message');
                    Sys.exit(1);
                case _:
            }
        }
        switch new Build(project, release, clean).run()
        {
            case Failure(_message):
                Sys.println('failed to build project $buildFile : $_message');
                Sys.exit(1);
            case _:
        }
    }

    @:command public function run()
    {
        final project = parseProject();

        if (!noRestore)
        {
            switch new Restore(project).run()
            {
                case Failure(_message):
                    Sys.println('failed to restore project $buildFile : $_message');
                    Sys.exit(1);
                case _:
            }
        }
        if (!noBuild)
        {
            switch new Build(project, release, clean).run()
            {
                case Failure(_message):
                    Sys.println('failed to build project $buildFile : $_message');
                    Sys.exit(1);
                case _:
            }
        }
        switch new Run(project).run()
        {
            case Failure(_message):
                Sys.println(_message);
                Sys.exit(1);
            case _:
        }
    }

    @:command public function restore()
    {
        switch new Restore(parseProject()).run()
        {
            case Failure(_message):
                Sys.println('failed to restore project $buildFile : $_message');
                Sys.exit(1);
            case _:
        }
    }

    @:command public function distribute()
    {
        //
    }

    function parseProject() : Project
        return Json.parse(File.getContent(buildFile));
}