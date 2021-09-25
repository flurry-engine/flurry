import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import tink.Cli;

function main()
{
    final args      = Sys.args();
    final flurrydir = Sys.getCwd();
    final calldir   = if (Sys.getEnv('HAXELIB_RUN') == '1') args.pop() else flurrydir;

    // cd into the calling directory, if we were ran from haxelib this will return us to the callers directory.
    // We want this as we want to output the exe in the project folder and use their npx / haxe setup.
    Sys.setCwd(calldir);

    Cli.process(args, new Flurry(calldir, flurrydir)).handle(Cli.exit);
}

class Flurry
{
    final callDir : String;

    final flurryDir : String;

    /**
     * Install the build tool in debug mode.
     */
    @:flag('--debug')
    @:alias('d')
    public var debug = false;

    /**
     * Clean the build directory before installing.
     * 
     * If you have already bootstrapped the build tool but need to re-install and run into linker errors, enable this flag.
     */
    @:flat('--clean')
    @:alias('c')
    public var clean = false;

    public function new(_callDir, _flurryDir)
    {
        callDir   = _callDir;
        flurryDir = _flurryDir;
    }

    /**
     * Bootstrap the igloo build tool.
     * 
     * This compiles the build tool to a native executable for the host platform.
     * It will be placed in a .flurry folder in the current directory.
     * 
     * A powershell or bash script will also be placed in the current directory for easy of calling.
     */
    @:command
    public function install()
    {
        final platform = Sys.systemName();
        final buildDir = Path.join([ callDir, '.flurry', 'igloo', platform ]);
        final haxeArgs = [
            'haxe',
            '-p', '$flurryDir/src/igloo/src',
            '-L', 'haxe-files',
            '-L', 'json2object',
            '-L', 'tink_cli',
            '-L', 'bin-packing',
            '-L', 'linc_stb',
            '-L', 'safety',
            '-L', 'format',
            '-L', 'console.hx',
            '-D', 'scriptable',
            '-D', 'analyzer-optimise',
            '-D', 'dll_export=$buildDir/export_classes.info',
            '-D', 'IGLOO_DLL_EXPORT=$buildDir/export_classes.info',
            '-D', 'IGLOO_SRC_CODEPATH=$flurryDir/src/igloo/src',
            '-D', 'IGLOO_BUILTIN_SCRIPTS=$flurryDir/src/igloo/scripts',
            '-D', 'HAXE_OUTPUT_FILE=Igloo',
            '-m', 'igloo.Igloo',
            '--dce', 'no',
            '--cpp', buildDir
        ];

        if (debug)
        {
            haxeArgs.push('--debug');
        }
        else
        {
            haxeArgs.push('--no-traces');
        }
        if (clean)
        {
            FileSystem.deleteDirectory(buildDir);
        }

        if (Sys.command('npx', haxeArgs) != 0)
        {
            Sys.stderr().writeString('failed to build igloo tool');
            Sys.exit(1);
        }

        if (Sys.systemName() == 'Windows')
        {
            File.saveContent(Path.join([ callDir, 'igloo.ps1' ]), '.\\.flurry\\igloo\\$platform\\Igloo.exe @args');
        }
        else
        {
            File.saveContent(Path.join([ callDir, 'igloo' ]), '#!/bin/bash\n./.flurry/igloo/$platform/Igloo "$@"');
        }
    }

    @:defaultCommand
    public function help()
    {
        Sys.println(Cli.getDoc(this));
    }
}