
import sys.FileSystem;
import sys.io.File;
import hxp.System;
import hxp.Path;
import hxp.Version;
import hxp.Script;
import hxp.HXML;

enum FlurryTarget {
    SnowDesktop;
    SnowWeb;
    SnowCLI;
    KhaDesktop;
    KhaWeb;
}

class Project extends Script
{
    /**
     * Meta data holds information about the overall project.
     */
    var meta : FlurryProjectMeta;

    /**
     * The app class controls build configurations specific to the binary/app output of a project.
     */
    var app : FlurryProjectApp;

    /**
     * The build class controls build specific configurations and files.
     */
    var build : FlurryProjectBuild;

    /**
     * List of directories relative to the build file and how they will be copied into the output directory relative to the binary.
     */
    var files : Map<String, String>;

    public final function new()
    {
        super();

        meta  = new FlurryProjectMeta();
        app   = new FlurryProjectApp();
        build = new FlurryProjectBuild();
        files = [];

        setup();

        snowBuild();
    }

    function setup()
    {
        //
    }

    // #region snow build

    final function snowBuild()
    {
        var user = new HXML();
        var snow = new HXML();
        var pathBuild   = Path.combine(app.output, System.hostPlatform + '-' + System.hostArchitecture.getName() + '.build');
        var pathRelease = Path.combine(app.output, System.hostPlatform + '-' + System.hostArchitecture.getName());

        FileSystem.createDirectory(pathBuild);
        FileSystem.createDirectory(pathRelease);

        snowAddGeneral(user, pathBuild);

        snowAddRequiredDefines(user);
        snowAddLibraryDefines(user);
        snowAddUserDefines(user);

        snowAddRequiredLibs(user);
        snowAddUserLibs(user);

        snowAddRequiredMacros(user, snow);
        snowAddUserMacros(user);

        snowWriteBuildFiles(user, snow, pathBuild);
        snowBuildProject(pathBuild, pathRelease);
    }

    final function snowAddGeneral(_user : HXML, _path : String)
    {
        _user.main = 'snow.App';
        _user.cpp  = Path.combine(_path, 'cpp');

        for (codepath in app.codepaths)
        {
            _user.cp(codepath);
        }
    }

    final function snowAddRequiredDefines(_user : HXML)
    {
        _user.define(System.hostPlatform);
        _user.define('target-cpp');
        _user.define('arch-64');
        _user.define('desktop');
        _user.define('hxcpp_static_std');
        _user.define('snow_use_glew');
        _user.define('snow_native');
    }

    final function snowAddLibraryDefines(_user : HXML)
    {
        _user.define('hxcpp'          );
        _user.define('haxe-concurrent');
        _user.define('linc_opengl'    );
        _user.define('linc_directx'   );
        _user.define('linc_sdl'       );
        _user.define('linc_ogg'       );
        _user.define('linc_stb'       );
        _user.define('linc_timestamp' );
        _user.define('linc_openal'    );
        _user.define('snow'           );

        for (lib in build.dependencies.keys())
        {
            _user.define(lib);
        }
    }

    final function snowAddUserDefines(_user : HXML)
    {
        for (define in build.defines)
        {
            _user.define(define);
        }
    }

    final function snowAddRequiredLibs(_user : HXML)
    {
        _user.lib('hxcpp'          , null);
        _user.lib('haxe-concurrent', null);
        _user.lib('linc_opengl'    , null);
        _user.lib('linc_directx'   , null);
        _user.lib('linc_sdl'       , null);
        _user.lib('linc_ogg'       , null);
        _user.lib('linc_stb'       , null);
        _user.lib('linc_timestamp' , null);
        _user.lib('linc_openal'    , null);
        _user.lib('snow'           , null);
    }

    final function snowAddUserLibs(_user : HXML)
    {
        for (lib => ver in build.dependencies)
        {
            _user.lib(lib, ver);
        }
    }

    final function snowAddRequiredMacros(_user : HXML, _snow : HXML)
    {
        _user.addMacro('snow.Set.assets("snow.core.native.assets.Assets")');
        _user.addMacro('snow.Set.runtime("snow.modules.sdl.Runtime")');
        _user.addMacro('snow.Set.audio("snow.modules.openal.Audio")');
        _user.addMacro('snow.Set.io("snow.modules.sdl.IO")');

        _snow.addMacro('snow.Set.main("${app.main}")');
        _snow.addMacro('snow.Set.ident("${app.namespace}")');
        _snow.addMacro('snow.Set.config("config.json")');
        _snow.addMacro('snow.Set.runtime("${ snowGetRuntimeString() }")');
        _snow.addMacro('snow.api.Debug.level(${ app.snow.log })');
    }

    final function snowAddUserMacros(_user : HXML)
    {
        for (mac in build.macros)
        {
            _user.addMacro(mac);
        }
    }

    final function snowGetRuntimeString() : String
    {
        if (app.snow.runtime != '')
        {
            return app.snow.runtime;
        }

        return switch (meta.target) {
            case SnowDesktop: 'uk.aidanlee.flurry.utils.runtimes.FlurryRuntimeDesktop';
            case SnowCLI:     'uk.aidanlee.flurry.utils.runtimes.FlurryRuntimeCLI';
            default: throw 'No snow runtime found for the target';
        }
    }

    final function snowWriteBuildFiles(_user : HXML, _snow : HXML, _path : String)
    {
        var user = File.write(Path.combine(_path, 'build.hxml'), false);
        var snow = File.write(Path.combine(_path, 'snow.hxml'), false);

        user.writeString(_user);
        user.writeString('\n');
        user.writeString(Path.combine(_path, 'snow.hxml'));

        snow.writeString(_snow);

        user.close();
        snow.close();
    }

    final function snowBuildProject(_pathBuild : String, _pathRelease : String)
    {
        // Build the project
        System.runCommand(workingDirectory, 'haxe', [ Path.combine(_pathBuild, 'build.hxml')]);

        // Copy files over
        for (src => dst in files)
        {
            System.recursiveCopy(src, Path.combine(_pathRelease, dst));
        }

        // Rename the output executable and copy it over to the .build directory.
        // Platform specific since file extensions change.
        switch (System.hostPlatform)
        {
            case WINDOWS : {
                FileSystem.rename(Path.join([ _pathBuild, 'cpp', 'App.exe' ]), Path.join([ _pathBuild, 'cpp', '${app.name}.exe' ]));
                System.copyFile(Path.join([ _pathBuild, 'cpp', '${app.name}.exe' ]), Path.combine(_pathRelease, '${app.name}.exe'));
            }
            case MAC : {
                //
            }
            case LINUX : {
                FileSystem.rename(Path.join([ _pathBuild, 'cpp', 'App' ]), Path.join([ _pathBuild, 'cpp', app.name ]));
                System.copyFile(Path.join([ _pathBuild, 'cpp', app.name ]), Path.combine(_pathRelease, app.name));
            }
        }
    }

    // #endregion
}

private class FlurryProjectMeta
{
    /**
     * The name of the project.
     */
    public var name : String;

    /**
     * The name of the author.
     */
    public var author : String;

    /**
     * The version number of the project.
     * Follows semantic versioning rules (https://semver.org/).
     */
    public var version : Version;

    /**
     * The output target of the project.
     */
    public var target : FlurryTarget;

    public function new()
    {
        name    = '';
        author  = '';
        version = Version.stringToVersion('0.0.1');
        target  = SnowDesktop;
    }
}

private class FlurryProjectApp
{
    /**
     * The output executable name.
     */
    public var name : String;

    /**
     * The bundle/package/app identifier, should be unique to you / your organisation.
     */
    public var namespace : String;

    /**
     * The output directory.
     */
    public var output : String;

    /**
     * The main class for haxe.
     * No .hx extension, just the name.
     */
    public var main : String;

    /**
     * List of local code directories for haxe to use (-cp).
     */
    public var codepaths : Array<String>;

    /**
     * Options exclusive to the snow backend.
     */
    public final snow : FlurrySnowOptions;

    public function new()
    {
        name      = 'flurry';
        namespace = 'flurry';
        output    = 'bin';
        main      = 'Main';
        codepaths = [ 'src' ];

        snow = new FlurrySnowOptions();
    }
}

private class FlurryProjectBuild
{
    /**
     * List of haxelib dependencies.
     * The key is the haxelib name and the value is the version.
     * If null is passed as the version the current active version is used.
     * 
     * Certain libraries will be automatically passed in depeneding on the target.
     * E.g. snow desktop target will add hxcpp and snow
     */
    public var dependencies : Map<String, String>;

    /**
     * List of macros to run at compile time (--macro).
     */
    public var macros : Array<String>;

    /**
     * List of defines to pass to the compiler (-Dvalue).
     */
    public var defines : Array<String>;

    public function new()
    {
        dependencies = [];
        macros       = [];
        defines      = [];
    }
}

private class FlurrySnowOptions
{
    /**
     * The name of the runtime to use.
     * If not set a runtime is chosen based on the target.
     */
    public var runtime : String;

    /**
     * The log level to use.
     */
    public var log : Int;

    public function new()
    {
        runtime = '';
        log     = 1;
    }
}
