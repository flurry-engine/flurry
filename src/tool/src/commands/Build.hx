package commands;

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
     * Location of the tools directory for the current platform.
     */
    final toolPath : String;

    /**
     * Location of the build directory for the current platform.
     */
    final buildPath : String;

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
     * Hxml file which will contain all snow related macros.
     */
    final snow : Hxml;

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

    public function new(_project : Project, _release : Bool, _clean : Bool, _fs : IFileSystem = null, _packer : Packer = null, _proc : Proc = null)
    {
        project     = _project;
        toolPath    = project.toolPath();
        buildPath   = project.buildPath();
        releasePath = project.releasePath();
        release     = _release;
        clean       = _clean;
        user        = new Hxml();
        snow        = new Hxml();
        fs          = _fs.or(new FileSystem());
        packer      = _packer.or(new Packer(project, fs));
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
        writeSnowHxml();

        final buildHxml = Path.join([ buildPath, 'build.hxml' ]);
        final snowHxml  = Path.join([ buildPath, 'snow.hxml' ]);
        fs.file.writeText(buildHxml, user.toString());
        fs.file.writeText(snowHxml, snow.toString());

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
        // By default the output executable is 'App' as 'snow.App' is '-main'

        switch Utils.platform()
        {
            case Windows:
                final exe = if (project!.build!.profile.or(Debug) == Release || release) 'App.exe' else 'App-debug.exe';
                final src = Path.join([ buildPath, 'cpp', exe ]);
                final dst = project.executable();

                fs.file.copy(src, dst);
            case Mac, Linux:
                final exe = if (project!.build!.profile.or(Debug) == Release || release) 'App' else 'App-debug';
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

        return Success(Unit.value);
    }

    /**
     * Write the user hxml. This contains all required and extra lib, defines, macros, etc.
     */
    function writeUserHxml()
    {
        user.main = 'snow.App';
        user.cpp  = Path.join([ buildPath, 'cpp' ]);
        user.dce  = std;

        if (project!.build!.profile.or(Debug) == Release || release)
        {
            user.noTraces();
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
        user.addDefine('HXCPP_GC_GENERATIONAL');
        user.addDefine('flurry-entry-point', project.app.main);
        user.addMacro('Safety.safeNavigation("uk.aidanlee.flurry")');

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
            user.addDefine(d.lib);
        }

        user.addHxml(Path.join([ buildPath, 'snow.hxml' ]));
    }

    /**
     * Write the snow related macro calls into the snow Hxml.
     */
    function writeSnowHxml()
    {
        final namespace = project!.app!.namespace.or('empty-project');
        final snowLog   = project!.build!.snow!.log.or(1);

        snow.addMacro('snow.Set.main("uk.aidanlee.flurry.snow.host.FlurrySnowHost")');
        snow.addMacro('snow.Set.ident("$namespace")');
        snow.addMacro('snow.Set.config("config.json")');
        snow.addMacro('snow.Set.runtime("${ snowRuntimeString() }")');
        snow.addMacro('snow.Set.assets("snow.core.native.assets.Assets")');
        snow.addMacro('snow.Set.audio("snow.core.Audio")');
        snow.addMacro('snow.Set.io("snow.modules.sdl.IO")');
        snow.addMacro('snow.api.Debug.level($snowLog)');
    }

    /**
     * Returns a string full the full package and module of the requested snow runtime.
     * @return String
     */
    function snowRuntimeString()
        return switch project!.build!.snow!.runtime.or(Desktop)
        {
            case Desktop: 'uk.aidanlee.flurry.snow.runtime.FlurrySnowDesktopRuntime';
            case Cli    : 'uk.aidanlee.flurry.snow.runtime.FlurrySnowCLIRuntime';
            case Custom(_package): _package;
        }
}