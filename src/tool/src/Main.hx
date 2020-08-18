package;

import Types.GraphicsBackend;
import haxe.io.Path;
import sys.io.abstractions.concrete.FileSystem;
import parcel.Packer;
import sys.io.abstractions.IFileSystem;
import sys.io.File;
import tink.Cli;
import tink.Json;
import Types.Project;
import commands.*;

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

    /**
     * If 
     */
    @:flag('restore')
    @:alias(false)
    public var restore = false;

    /**
     * If the output executable should be launched after building.
     * default : false
     */
    @:flag('run')
    @:alias(false)
    public var run = false;

    /**
     * If set the build directory will be delected before building.
     * default : false
     */
    @:flag('clean')
    @:alias('c')
    public var clean = false;

    /**
     * If set this will build in release mode and package the produced executable and assets for distribution.
     * default : false
     */
    @:flag('distribute')
    @:alias('d')
    public var distribute = false;

    @:flag('verbose')
    @:alias('v')
    public var verbose = false;

    /**
     * Path to the json build file.
     * default : build.json
     */
    @:flag('file')
    @:alias('f')
    public var buildFile = 'build.json';

    /**
     * Force the use of a specific graphics backend for the target platform.
     * If the requested backend is not usable on the target platform, compilation will end.
     * - `auto`  - Atomatically select the best backend based for the target.
     * - `mock`  - Produces no output, simply applies some basic checks on all requests.
     * - `d3d11` - Use the Direct3D 11.1 backend (Windows only)
     * - `ogl3`  - Use the OpenGL 3.3 backend (Windows, Mac, and Linux only)
     */
    @:flag('gpu')
    @:alias('g')
    public var graphicsBackend = 'auto';

    @:flag('target')
    @:alias('t')
    public var target = 'desktop';

    /**
     * Process object used for invoking other processes.
     */
    final proc : Proc;

    final net : Net;

    /**
     * Interface for accessing files and directories.
     */
    final fs : IFileSystem;

    public function new(_fs : IFileSystem = null, _net : Net = null, _proc : Proc = null)
    {
        fs   = _fs.or(new FileSystem());
        net  = _net.or(new Net());
        proc = _proc.or(new Proc());
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
        final projectPath = sys.FileSystem.absolutePath(buildFile);
        final project     = parseProject(buildFile);
        final toolPath    = project.toolPath();
        final buildPath   = project.buildPath();
        final releasePath = project.releasePath();

        if (restore)
        {
            switch new Restore(project, fs, net, proc).run()
            {
                case Failure(_message):
                    Sys.println('failed to restore project $buildFile : $_message');
                    Sys.exit(1);
                case _:
            }
        }

        // Ensure our base directories are created.
        if (clean)
        {
            fs.directory.remove(buildPath);
            fs.directory.remove(releasePath);
        }
        fs.directory.create(buildPath);
        fs.directory.create(releasePath);

        // Generate a hxml file from the project and invoke haxe
        final hxmlPath = Path.join([ buildPath, 'build.hxml' ]);
        final hxmlData = generateHxml(project, projectPath, distribute, graphicsBackend);
        fs.file.writeText(hxmlPath, hxmlData);

        switch proc.run('npx', [ 'haxe', hxmlPath ], true)
        {
            case Success(_):
            case Failure(message): panic(message);
        }

        // Generate all parcels
        final debugParcels   = Path.join([ buildPath, 'cpp', 'assets', 'parcels' ]);
        final releaseParcels = Path.join([ releasePath, 'assets', 'parcels' ]);
        final packer         = new Packer(project, verbose, verifyGraphicsBackend(graphicsBackend), fs, proc);

        fs.directory.create(debugParcels);
        fs.directory.create(releaseParcels);

        for (assets in project!.parcels.or([]))
        {
            switch packer.create(assets)
            {
                case Success(parcels):
                    for (parcel in parcels)
                    {
                        fs.file.copy(parcel.file, Path.join([ debugParcels, parcel.name ]));
                        fs.file.copy(parcel.file, Path.join([ releaseParcels, parcel.name ]));
                    }
                case Failure(message): panic(message);
            }
        }

        // Copy over the executable
        switch Utils.platform()
        {
            case Windows:
                final src = Path.join([ buildPath, 'cpp', '${ project.app.name }.exe' ]);
                final dst = project.executable();

                fs.file.copy(src, dst);
            case Mac, Linux:
                final src = Path.join([ buildPath, 'cpp', project.app.name ]);
                final dst = project.executable();

                fs.file.copy(src, dst);

                switch proc.run('chmod', [ 'a+x', dst ], true)
                {
                    case Failure(message): panic(message);
                    case _://
                }
        }

        // Remove all temp directories
        fs.directory.remove(project.baseTempDir());

        // Copy globbed files
        if (project!.build!.files != null)
        {
            for (glob => dst in project!.build!.files.unsafe())
            {
                final ereg       = GlobPatterns.toEReg(glob);
                final source     = glob.substringBefore('*').substringBeforeLast('/'.code);
                final buildDst   = Path.join([ buildPath, 'cpp', dst ]);
                final releaseDst = Path.join([ releasePath, dst ]);

                for (file in fs.walk(source, []))
                {
                    if (ereg.match(file))
                    {
                        final path = new Path(file);

                        fs.file.copy(file, Path.join([ buildDst, '${ path.file }.${ path.ext }' ]));
                        fs.file.copy(file, Path.join([ releaseDst, '${ path.file }.${ path.ext }' ]));
                    }
                }
            }
        }

        // Run
        if (run)
        {
            proc.run(project.executable(), [], true);
        }
    }

    static function panic(_error : String)
    {
        Sys.println(_error);
        Sys.exit(1);
    }

    static function parseProject(_file : String) : Project
        return Json.parse(File.getContent(_file));

    static function verifyGraphicsBackend(_api : String) : GraphicsBackend
    {
        return switch _api
        {
            case 'mock'  : Mock;
            case 'ogl3'  : Ogl3;
            case 'd3d11' : if (Utils.platform() == Windows) D3d11 else Ogl3;
            case _:
                switch Utils.platform()
                {
                    case Windows: D3d11;
                    case _: Ogl3;
                }
        }
    }

    static function generateHxml(_project : Project, _projectPath : String, _distribute : Bool, _gpu : String)
    {
        final hxml = new Hxml();

        hxml.main = 'uk.aidanlee.flurry.hosts.SDLHost';
        hxml.cpp  = Path.join([ _project.buildPath(), 'cpp' ]);
        hxml.dce  = std;

        if (_project!.build!.profile.or(Debug) == Release || _distribute)
        {
            hxml.noTraces();
            hxml.addDefine('no-debug');
        }
        else
        {
            hxml.debug();
        }

        hxml.addDefine(Utils.platform());
        hxml.addDefine('target-cpp');
        hxml.addDefine('desktop');
        hxml.addDefine('snow_native');
        hxml.addDefine('HXCPP_M64');
        hxml.addDefine('HAXE_OUTPUT_FILE', _project.app.name);
        hxml.addDefine('flurry-entry-point', _project.app.main);
        hxml.addDefine('flurry-build-file', _projectPath);
        hxml.addDefine('flurry-gpu-api', _gpu);
        hxml.addMacro('Safety.safeNavigation("uk.aidanlee.flurry")');
        hxml.addMacro('nullSafety("uk.aidanlee.flurry.modules", Strict)');
        hxml.addMacro('nullSafety("uk.aidanlee.flurry.api", Strict)');

        for (p in _project.app.codepaths)
        {
            hxml.addClassPath(p);
        }

        for (d in _project!.build!.defines.or([]))
        {
            hxml.addDefine(d.def, d.value);
        }

        for (m in _project!.build!.macros.or([]))
        {
            hxml.addMacro(m);
        }

        for (d in _project!.build!.dependencies.or([]))
        {
            hxml.addLibrary(d.lib, d.version);
        }

        return hxml.toString();
    }
}