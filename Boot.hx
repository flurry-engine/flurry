import sys.FileSystem;
import sys.io.File;
import haxe.Http;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import tink.Cli;

function main()
{
    final args      = Sys.args();
    final flurryDir = Sys.getCwd();
    final callDir   = if (Sys.getEnv('HAXELIB_RUN') == '1') args.pop() else flurryDir;

    // cd into the calling directory, if we were ran from haxelib this will return us to the callers directory.
    // We want this as we want to output the exe in the project folder and use their npx / haxe setup.
    Sys.setCwd(callDir);

    Cli.process(args, new Flurry(callDir, flurryDir)).handle(Cli.exit);
}

class Flurry
{
    final callDir : String;

    final flurryDir : String;

    final platform : String;

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
    @:flag('--clean')
    @:alias('c')
    public var clean = false;

    /**
     * Path to the projects .haxerc file.
     * 
     * If left blank the current directory is checked.
     */
    @:flag('--haxerc')
    @:alias('h')
    public var haxerc = '';

    public function new(_callDir, _flurryDir)
    {
        callDir   = _callDir;
        flurryDir = _flurryDir;
        platform  = Sys.systemName();
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
        downloadHaxe();
        compileIgloo();
    }

    @:defaultCommand
    public function help()
    {
        Sys.println(Cli.getDoc(this));
    }

    function downloadHaxe()
    {
        final haxercFile = if (haxerc == '') Path.join([ callDir, '.haxerc' ]) else haxerc;

        if (!FileSystem.exists(haxercFile))
        {
            Sys.println('.haxerc file does not exist at "$haxercFile"');
            Sys.exit(1);
        }

        final haxeDir    = Path.join([ callDir, '.flurry', 'haxe', platform]);
        final haxercData = haxe.Json.parse(File.getContent(haxercFile));

        if (haxercData.version != haxeDir)
        {
            Sys.println('.haxerc version does not match the expected haxe path');
            Sys.println('updating .haxerc file');

            haxercData.version = haxeDir;

            File.saveContent(haxercFile, haxe.Json.stringify(haxercData));
        }

        if (!FileSystem.exists(haxeDir))
        {
            FileSystem.createDirectory(haxeDir);

            final url = switch platform {
                case 'Windows':
                    'https://github.com/flurry-engine/haxe/releases/download/4.2.4-flurry.1/windows.tar.gz';
                case 'Mac':
                    'https://github.com/flurry-engine/haxe/releases/download/4.2.4-flurry.1/mac.tar.gz';
                case 'Linux':
                    'https://github.com/flurry-engine/haxe/releases/download/4.2.4-flurry.1/linux.tar.gz';
                case other:
                    Sys.println('platform $other is not supported');
                    Sys.exit(1);

                    '';
            }

            Sys.println('haxe is not downloaded');
            Sys.println('downloading from $url');

            final zip     = download(url);
            final input   = new BytesInput(zip);
            final entries = new format.tgz.Reader(input).read();

            for (entry in entries)
            {
                final absPath = Path.join([ haxeDir, entry.fileName ]);

                if (StringTools.endsWith(entry.fileName, '/'))
                {
                    if (!FileSystem.exists(absPath))
                    {
                        FileSystem.createDirectory(absPath);
                    }
                }
                else
                {
                    File.saveBytes(absPath, entry.data);
                }
            }
        }
    }

    function compileIgloo()
    {
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
            '-D', 'analyzer-optimize',
            '-D', 'dll_export=$buildDir/export_classes.info',
            '-D', 'IGLOO_DLL_EXPORT=$buildDir/export_classes.info',
            '-D', 'IGLOO_SRC_CODEPATH=$flurryDir/src/igloo/src',
            '-D', 'IGLOO_BUILTIN_SCRIPTS=$flurryDir/src/igloo/scripts',
            '-D', 'HAXE_OUTPUT_FILE=Igloo',
            '-D', 'HXCPP_M64',
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

        if (platform == 'Windows')
        {
            File.saveContent(Path.join([ callDir, 'igloo.ps1' ]), '.\\.flurry\\igloo\\$platform\\Igloo.exe @args');
        }
        else
        {
            File.saveContent(Path.join([ callDir, 'igloo' ]), '#!/bin/bash\n./.flurry/igloo/$platform/Igloo "$@"');
        }
    }

    private function download(_url)
    {
        var code  = 0;
        var bytes = Bytes.alloc(0);
    
        final request = new Http(_url);
        request.onStatus = v -> code = v;
        request.onError  = s -> {
            Sys.println('Failed to download haxe with error code $s');
            Sys.exit(1);
        }
        request.onBytes  = data -> {
            switch code
            {
                case 200:
                    bytes = data;
                case 302:
                    // Github returns redirects as <html><body><a href="redirect url"></body></html>
                    final access = new haxe.xml.Access(Xml.parse(data.toString()).firstElement());
                    final redir  = access.node.body.node.a.att.href;
    
                    bytes = download(redir);
                case other:
                    Sys.println('Failed to download haxe with error code $other');
                    Sys.exit(1);
            }
        }
        request.request();
    
        return bytes;
    }
}