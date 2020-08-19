package commands;

import Types.Project;
import Types.GraphicsBackend;
import tink.Cli;
import tink.Json;
import parcel.Packer;
import sys.io.abstractions.concrete.FileSystem;
import sys.io.abstractions.IFileSystem;
import haxe.io.Path;

using Utils;
using Safety;

class Build
{
    /**
     * If set the output executable will be launched after building.
     */
    @:flag('run')
    @:alias('r')
    public var run = false;

    /**
     * If set the build directory will be delected before building.
     */
    @:flag('clean')
    @:alias('c')
    public var clean = false;

    /**
     * If set this will build with all optimisations enabled and debug output disabled.
     */
    @:flag('release')
    @:alias('d')
    public var release = false;

    /**
     * If enabled the output of all tools (shader compilers, texture packer, etc) will be displayed. Haxe compiler and project output will always be displayed.
     */
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

    /**
     * Target to build the project to.
     * Can be any of the following.
     * - `desktop` - Build the project as a native executable for the host operating system.
     */
    @:flag('target')
    @:alias('t')
    public var target = 'desktop';

    /**
     * Process object used for invoking other processes.
     */
    final proc : Proc;

    /**
     * Network object used for downloading files.
     */
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

    /**
     * Prints out help about the build command.
     */
    @:command public function help()
    {
        Console.success('Build');
        Console.println(Cli.getDoc(this));
    }

    /**
     * The build command will take your code and assets and compile them into a runnable executable for the specified target.
     * It can optionally launch the executable on successfully building.
     */
    @:defaultCommand public function build()
    {
        final projectPath = sys.FileSystem.absolutePath(buildFile);
        final project     = parseProject(fs, buildFile);
        final toolPath    = project.toolPath();
        final buildPath   = project.buildPath();
        final releasePath = project.releasePath();

        // Restore the project.
        switch new Restore(project, fs, net, proc).run()
        {
            case Failure(_message): panic(_message);
            case _:
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
        Console.success('Compiling Haxe');

        final gpu      = verifyGraphicsBackend(graphicsBackend);
        final hxmlPath = Path.join([ buildPath, 'build.hxml' ]);
        final hxmlData = generateHxml(project, projectPath, release, gpu);
        fs.file.writeText(hxmlPath, hxmlData);

        switch proc.run('npx', [ 'haxe', hxmlPath ], true)
        {
            case Success(_):
            case Failure(message): panic(message);
        }

        // Generate all parcels
        Console.success('Generating Parcels');

        final debugParcels   = Path.join([ buildPath, 'cpp', 'assets', 'parcels' ]);
        final releaseParcels = Path.join([ releasePath, 'assets', 'parcels' ]);
        final packer         = new Packer(project, verbose, gpu, fs, proc);

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
                    case _: //
                }
        }

        // Remove all temp directories
        fs.directory.remove(project.baseTempDir());

        // Copy globbed files
        if (project!.build!.files != null)
        {
            Console.success('Copying Globbed Files');

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
            Console.success('Running Project');

            proc.run(project.executable(), [], true);
        }

        Console.success('Building Completed');
    }

    /**
     * Log the provided string as an error and exit with a non zero return code.
     * @param _error Error message to log.
     */
    static function panic(_error : String)
    {
        Console.error(_error);
        Sys.exit(1);
    }

    /**
     * Parse the json string at the provided file location.
     */
    static function parseProject(_fs : IFileSystem, _file : String) : Project
    {
        return Json.parse(_fs.file.getText(_file));
    }

    /**
     * Parse the graphics backend string into its enum equivilent.
     */
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

    /**
     * Generates a hxml file for the given project.
     * @param _project Project.
     * @param _projectPath Absolute path to project file.
     * @param _release If the project is to be built in release mode.
     * @param _gpu Graphics api to build with.
     * @return String
     */
    static function generateHxml(_project : Project, _projectPath : String, _release : Bool, _gpu : GraphicsBackend) : String
    {
        final hxml = new Hxml();

        hxml.main = 'uk.aidanlee.flurry.hosts.SDLHost';
        hxml.cpp  = Path.join([ _project.buildPath(), 'cpp' ]);
        hxml.dce  = std;

        if (_project!.build!.profile.or(Debug) == Release || _release)
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
        hxml.addDefine('flurry-gpu-api', switch _gpu {
            case Mock: 'mock';
            case Ogl3: 'ogl3';
            case D3d11: 'd3d11';
        });
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