import sys.io.File;
import haxe.io.Path;

function main()
{
    final args      = Sys.args();
    final flurrydir = Sys.getCwd();
    final calldir   = if (Sys.getEnv('HAXELIB_RUN') == '1') args.pop() else flurrydir;

    if (args.length == 0)
    {
        Sys.println('no command provided');
        Sys.exit(1);
    }

    switch args.shift()
    {
        case 'install':
            // cd into the calling directory, if we were ran from haxelib this will return us to the callers directory.
            // We want this as we want to output the exe in the project folder and use their npx / haxe setup.
            Sys.setCwd(calldir);

            final buildDir = Path.join([ calldir, '.flurry', 'igloo' ]);
            final haxeArgs = [
                'haxe',
                '-p', '$flurrydir/src/igloo/src',
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
                '-D', 'IGLOO_SRC_CODEPATH=$flurrydir/src/igloo/src',
                '-D', 'IGLOO_BUILTIN_SCRIPTS=$flurrydir/src/igloo/scripts',
                '-D', 'HAXE_OUTPUT_FILE=Igloo',
                '-m', 'igloo.Igloo',
                '--dce', 'no',
                '--cpp', buildDir
            ];

            for (arg in args)
            {
                haxeArgs.push(arg);
            }
            
            if (Sys.command('npx', haxeArgs) != 0)
            {
                Sys.stderr().writeString('failed to build igloo tool');
                Sys.exit(1);
            }

            if (Sys.systemName() == 'Windows')
            {
                File.saveContent(Path.join([ calldir, 'igloo.ps1' ]), '.\\.flurry\\igloo\\Igloo.exe @args');
            }
            else
            {
                File.saveContent(Path.join([ calldir, 'igloo' ]), '#!/bin/bash\n./.flurry/igloo/Igloo "$@"');
            }

        case 'path':
            // TODO : print the cwd to stdout and exit.
    }
}