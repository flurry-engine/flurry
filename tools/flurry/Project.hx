
import sys.io.File;
import sys.FileSystem;
import hxp.System;
import hxp.Path;
import hxp.Version;
import hxp.Script;
import hxp.HXML;

enum FlurryTarget {
    Haxe;
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

        var pathBuild   = Path.combine(app.output, System.hostPlatform + '-' + System.hostArchitecture.getName() + '.build');
        var pathRelease = Path.combine(app.output, System.hostPlatform + '-' + System.hostArchitecture.getName());

        switch (command)
        {
            case 'build':
                switch (meta.target)
                {
                    case Haxe:
                        haxeBuild(pathBuild, pathRelease);
                    case SnowDesktop, SnowCLI:
                        snowBuild(pathBuild, pathRelease);
                    case _target:
                        throw 'building for $_target is not yet implemented';
                }

            case 'run':
                switch (meta.target)
                {
                    case Haxe:
                        haxeBuild(pathBuild, pathRelease);
                        haxeRun(pathRelease);
                    case SnowDesktop, SnowCLI:
                        snowBuild(pathBuild, pathRelease);
                        snowRun(pathRelease);
                    case _target:
                        throw 'running for $_target is not yet implemented';
                }

            case 'package':
                switch (meta.target)
                {
                    case Haxe:
                        haxeBuild(pathBuild, pathRelease);
                        haxePackage(pathRelease);
                    case SnowDesktop, SnowCLI:
                        snowBuild(pathBuild, pathRelease);
                        snowPackage(pathRelease);
                    case _target:
                        throw 'running for $_target is not yet implemented';
                }

            case 'clean':
                cleanOutputDirectory();

            case 'default':
                // TODO : Error
        }
    }

    /**
     * Overridable function, users should configure their project build in this function.
     */
    function setup()
    {
        //
    }

    final function cleanOutputDirectory()
    {
        System.removeDirectory(app.output);
    }

    // #region haxe build

    final function haxeBuild(_pathBuild : String, _pathRelease : String)
    {
        var user = new HXML();

        FileSystem.createDirectory(_pathBuild);
        FileSystem.createDirectory(_pathRelease);

        user.main  = app.main;
        user.cpp   = Path.combine(_pathBuild, 'cpp');
        user.debug = build.debug;

        for (codepath in app.codepaths)
        {
            user.cp(codepath);
        }

        // Add some defines for cpp target
        user.define(System.hostPlatform);
        user.define('target-cpp');
        user.define('arch-64');
        user.define('desktop');
        user.define('hxcpp');

        for (lib in build.dependencies.keys())
        {
            user.define(lib);
        }

        for (define in build.defines)
        {
            user.define(define);
        }

        user.lib('hxcpp', null);

        for (lib => ver in build.dependencies)
        {
            user.lib(lib, ver);
        }

        for (mac in build.macros)
        {
            user.addMacro(mac);
        }

        var hxmlUser = File.write(Path.combine(_pathBuild, 'build.hxml'), false);
        hxmlUser.writeString(user);
        hxmlUser.close();

        // Build the project
        var result = System.runCommand(workingDirectory, 'haxe', [ Path.combine(_pathBuild, 'build.hxml')]);
        if (result != 0)
        {
            Sys.exit(result);
        }

        // Copy files over
        for (src => dst in files)
        {
            System.recursiveCopy(src, Path.combine(_pathRelease, dst));
        }

        // Rename the output executable and copy it over to the .build directory.
        // Platform specific since file extensions change.
        // If the script is called with the 'run' command i.e. `hxp .. build.hxp run` then the binary should be launched after building.
        switch (System.hostPlatform)
        {
            case WINDOWS : {
                FileSystem.rename(Path.join([ _pathBuild, 'cpp', '${app.main}.exe' ]), Path.join([ _pathBuild, 'cpp', '${app.name}.exe' ]));
                System.copyFile(Path.join([ _pathBuild, 'cpp', '${app.name}.exe' ]), Path.combine(_pathRelease, '${app.name}.exe'));
            }
            case MAC : {
                //
            }
            case LINUX : {
                FileSystem.rename(Path.join([ _pathBuild, 'cpp', '${app.main}' ]), Path.join([ _pathBuild, 'cpp', app.name ]));
                System.copyFile(Path.join([ _pathBuild, 'cpp', app.name ]), Path.combine(_pathRelease, app.name));

                System.runCommand(workingDirectory, 'chmod a+x ${Path.join([ _pathBuild, 'cpp', app.name ])}', []);
                System.runCommand(workingDirectory, 'chmod a+x ${Path.join([ _pathRelease, app.name ])}', []);
            }
        }
    }

    final function haxeRun(_pathRelease : String)
    {
        switch (System.hostPlatform)
        {
            case WINDOWS:
                System.runCommand(workingDirectory, Path.combine(_pathRelease, '${app.name}.exe'), []);
            
            case MAC:
                //

            case LINUX:
                System.runCommand(workingDirectory, Path.join([ _pathRelease, app.name ]), []);
        }
    }

    final function haxePackage(_pathRelease : String)
    {
        System.compress(_pathRelease, Path.combine(app.output, '${app.name}-${System.hostPlatform}${System.hostArchitecture.getName()}.zip'));
    }

    // #endregion

    // #region snow build

    final function snowBuild(_pathBuild : String, _pathRelease : String)
    {
        var user = new HXML();
        var snow = new HXML();

        FileSystem.createDirectory(_pathBuild);
        FileSystem.createDirectory(_pathRelease);

        // General snow settings
        user.main  = 'snow.App';
        user.cpp   = Path.combine(_pathBuild, 'cpp');
        user.debug = build.debug;

        for (codepath in app.codepaths)
        {
            user.cp(codepath);
        }

        // Add snow required defines, user specified defines, and a define for each libraries name.
        user.define(System.hostPlatform);
        user.define('target-cpp');
        user.define('arch-64');
        user.define('desktop');
        user.define('hxcpp_static_std');
        user.define('snow_use_glew');
        user.define('snow_native');
        
        user.define('hxcpp'          );
        user.define('haxe-concurrent');
        user.define('linc_opengl'    );
        user.define('linc_directx'   );
        user.define('linc_sdl'       );
        user.define('linc_ogg'       );
        user.define('linc_stb'       );
        user.define('linc_timestamp' );
        user.define('linc_openal'    );
        user.define('snow'           );

        for (lib in build.dependencies.keys())
        {
            user.define(lib);
        }

        for (define in build.defines)
        {
            user.define(define);
        }

        // Add snow required libraries and user specified libraries.
        user.lib('hxcpp'          , null);
        user.lib('haxe-concurrent', null);
        user.lib('linc_opengl'    , null);
        user.lib('linc_directx'   , null);
        user.lib('linc_sdl'       , null);
        user.lib('linc_ogg'       , null);
        user.lib('linc_stb'       , null);
        user.lib('linc_timestamp' , null);
        user.lib('linc_openal'    , null);
        user.lib('snow'           , null);

        for (lib => ver in build.dependencies)
        {
            user.lib(lib, ver);
        }

        // Add snow required macros and user specified macros.
        user.addMacro('snow.Set.assets("snow.core.native.assets.Assets")');
        user.addMacro('snow.Set.runtime("snow.modules.sdl.Runtime")');
        user.addMacro('snow.Set.audio("snow.modules.openal.Audio")');
        user.addMacro('snow.Set.io("snow.modules.sdl.IO")');

        snow.addMacro('snow.Set.main("${app.main}")');
        snow.addMacro('snow.Set.ident("${app.namespace}")');
        snow.addMacro('snow.Set.config("config.json")');
        snow.addMacro('snow.Set.runtime("${ snowGetRuntimeString() }")');
        snow.addMacro('snow.api.Debug.level(${ app.snow.log })');

        for (mac in build.macros)
        {
            user.addMacro(mac);
        }

        // Write the two snow build hxmls and build them.
        var hxmlUser = File.write(Path.combine(_pathBuild, 'build.hxml'), false);
        var hxmlSnow = File.write(Path.combine(_pathBuild, 'snow.hxml'), false);

        hxmlUser.writeString(user);
        hxmlUser.writeString('\n');
        hxmlUser.writeString(Path.combine(_pathBuild, 'snow.hxml'));

        hxmlSnow.writeString(snow);

        hxmlUser.close();
        hxmlSnow.close();

        // Build the project
        var result = System.runCommand(workingDirectory, 'haxe', [ Path.combine(_pathBuild, 'build.hxml')]);
        if (result != 0)
        {
            Sys.exit(result);
        }

        // Copy files over
        for (src => dst in files)
        {
            System.recursiveCopy(src, Path.combine(_pathRelease, dst));
        }

        // Rename the output executable and copy it over to the .build directory.
        // Platform specific since file extensions change.
        // If the script is called with the 'run' command i.e. `hxp .. build.hxp run` then the binary should be launched after building.
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

                System.runCommand(workingDirectory, 'chmod a+x ${Path.join([ _pathBuild, 'cpp', app.name ])}', []);
                System.runCommand(workingDirectory, 'chmod a+x ${Path.join([ _pathRelease, app.name ])}', []);
            }
        }
    }

    final function snowRun(_pathRelease : String)
    {
        switch (System.hostPlatform)
        {
            case WINDOWS:
                System.runCommand(workingDirectory, Path.combine(_pathRelease, '${app.name}.exe'), []);
            
            case MAC:
                //

            case LINUX:
                System.runCommand(workingDirectory, Path.join([ _pathRelease, app.name ]), []);
        }
    }

    final function snowPackage(_pathRelease : String)
    {
        System.compress(_pathRelease, Path.combine(app.output, '${app.name}-${System.hostPlatform}${System.hostArchitecture.getName()}.zip'));
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
     * If this build will be built in debug mode.
     */
    public var debug : Bool;

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
