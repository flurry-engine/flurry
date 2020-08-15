package commands;

import Types.GraphicsBackend;
import Types.Project;
import parcel.Packer;
import haxe.io.Path;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;
import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;

using Safety;
using Utils;

class Build
{
    /**
     * The project to build.
     */
    final project : Project;

    /**
     * If the project will be built in release mode.
     */
    final release : Bool;

    /**
     * If the output directories will be removed before building.
     */
    final clean : Bool;

    /**
     * Absolute path to the build file.
     */
    final buildFile : String;

    /**
     * Location of the tools directory for the current platform.
     */
    final toolPath : String;

    /**
     * Location of the build directory for the current platform.
     */
    final buildPath : String;

    /**
     * The requested graphics backend to be used.
     */
    final gpu : GraphicsBackend;

    /**
     * Location of the release directory for the current platform.
     * The release directory will contain just the built executable and parcels, not any extra intermediate data.
     */
    final releasePath : String;

    /**
     * Hxml file generated to build the haxe code.
     */
    final user : Hxml;

    /**
     * Packer object which will be used for generating parcel data.
     */
    final packer : Packer;

    /**
     * Process object used for invoking other processes.
     */
    final proc : Proc;

    /**
     * Interface for accessing files and directories.
     */
    final fs : IFileSystem;

    public function new(
        _project : Project,
        _release : Bool,
        _clean : Bool,
        _buildFile : String,
        _gpu : String,
        _fs : IFileSystem = null,
        _packer : Packer = null,
        _proc : Proc = null)
    {
        project     = _project;
        toolPath    = project.toolPath();
        buildPath   = project.buildPath();
        releasePath = project.releasePath();
        release     = _release;
        clean       = _clean;
        buildFile   = _buildFile;
        user        = new Hxml();
        gpu         = verifyGraphicsBackend(_gpu);
        fs          = _fs.or(new FileSystem());
        packer      = _packer.or(new Packer(project, gpu, fs));
        proc        = _proc.or(new Proc());
    }

    /**
     * Compile the haxe code and create the parcels.
     * @return Result<Unit>
     */
    public function run() : Result<Unit, String>
    {
        if (clean)
        {
            fs.directory.remove(buildPath);
            fs.directory.remove(releasePath);
        }

        fs.directory.create(buildPath);
        fs.directory.create(releasePath);

        // Output and compile the actual haxe program

        writeUserHxml();

        final buildHxml = Path.join([ buildPath, 'build.hxml' ]);
        fs.file.writeText(buildHxml, user.toString());

        switch proc.run('npx', [ 'haxe', buildHxml ])
        {
            case Failure(message):
                return Failure(message);
            case _:
                //
        }

        // Generate all parcels for this project

        final debugParcels   = Path.join([ buildPath, 'cpp', 'assets', 'parcels' ]);
        final releaseParcels = Path.join([ releasePath, 'assets', 'parcels' ]);

        fs.directory.create(debugParcels);
        fs.directory.create(releaseParcels);

        for (assets in project!.parcels.or([]))
        {
            switch packer.create(assets)
            {
                case Success(data):
                    for (parcel in data)
                    {
                        fs.file.copy(parcel.file, Path.join([ debugParcels, parcel.name ]));
                        fs.file.copy(parcel.file, Path.join([ releaseParcels, parcel.name ]));
                    }
                case Failure(message): return Failure(message);
            }
        }

        // Rename the output executables according to the project name

        switch Utils.platform()
        {
            case Windows:
                final exe = if (project!.build!.profile.or(Debug) == Release || release) 'SDLHost.exe' else 'SDLHost-debug.exe';
                final src = Path.join([ buildPath, 'cpp', exe ]);
                final dst = project.executable();

                fs.file.copy(src, dst);
            case Mac, Linux:
                final exe = if (project!.build!.profile.or(Debug) == Release || release) 'SDLHost' else 'SDLHost-debug';
                final src = Path.join([ buildPath, 'cpp', exe ]);
                final dst = project.executable();

                fs.file.copy(src, dst);

                switch proc.run('chmod', [ 'a+x', dst ])
                {
                    case Failure(message):
                        return Failure(message);
                    case _:
                        //
                }
        }

        fs.directory.remove(project.baseTempDir());

        // Post build tasks.

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

        return Success(Unit.value);
    }

    /**
     * Write the user hxml. This contains all required and extra lib, defines, macros, etc.
     */
    function writeUserHxml()
    {
        user.main = 'uk.aidanlee.flurry.hosts.SDLHost';
        user.cpp  = Path.join([ buildPath, 'cpp' ]);
        user.dce  = std;

        if (project!.build!.profile.or(Debug) == Release || release)
        {
            user.noTraces();
            user.addDefine('no-debug');
        }
        else
        {
            user.debug();
        }

        user.addDefine(Utils.platform());
        user.addDefine('target-cpp');
        user.addDefine('desktop');
        user.addDefine('snow_native');
        user.addDefine('HXCPP_M64');
        user.addDefine('flurry-entry-point', project.app.main);
        user.addDefine('flurry-build-file', buildFile);
        user.addDefine('flurry-gpu-api', switch gpu {
            case Mock: 'mock';
            case Ogl3: 'ogl3';
            case D3d11: 'd3d11';
        });
        user.addMacro('Safety.safeNavigation("uk.aidanlee.flurry")');
        user.addMacro('nullSafety("uk.aidanlee.flurry.modules", Strict)');
        user.addMacro('nullSafety("uk.aidanlee.flurry.api", Strict)');

        for (p in project.app.codepaths)
        {           
            user.addClassPath(p);
        }

        for (d in project!.build!.defines.or([]))
        {
            user.addDefine(d.def, d.value);
        }

        for (m in project!.build!.macros.or([]))
        {
            user.addMacro(m);
        }

        for (d in project!.build!.dependencies.or([]))
        {
            user.addLibrary(d.lib, d.version);
        }
    }

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
}