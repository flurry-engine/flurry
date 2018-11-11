package uk.aidanlee.flurry.utils.build;

import sys.FileSystem;
import sys.io.File;
import hxp.System;
import hxp.Path;
import hxp.Version;
import hxp.Script;
import hxp.HXML;

class FlurryProject extends Script
{
    var meta : FlurryProjectMeta;

    var app : FlurryProjectApp;

    var build : FlurryProjectBuild;

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
        _snow.addMacro('snow.Set.runtime("uk.aidanlee.flurry.utils.runtimes.FlurryRuntimeDesktop")');
    }

    final function snowAddUserMacros(_user : HXML)
    {
        for (mac in build.macros)
        {
            _user.addMacro(mac);
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
        System.runProcess(workingDirectory, 'haxe', [ Path.combine(_pathBuild, 'build.hxml')] );

        // Copy files over
        for (src => dst in files)
        {
            System.recursiveCopy(src, Path.combine(_pathRelease, dst));
        }

        // Copy the output binary to the release folder and rename it to what the user requested
        // TODO : Make this work for Windows and OSX, assumes no file extension right now.
        System.copyFile(Path.join([ _pathBuild, 'cpp', 'App' ]), Path.combine(_pathRelease, app.name));
    }

    // #endregion
}

private class FlurryProjectMeta
{
    public var name : String;

    public var author : String;

    public var version : Version;

    public function new()
    {
        name    = '';
        author  = '';
        version = Version.stringToVersion('0.0.1');
    }
}

private class FlurryProjectApp
{
    public var name : String;

    public var namespace : String;

    public var output : String;

    public var main : String;

    public var codepaths : Array<String>;

    public function new()
    {
        name      = 'flurry';
        namespace = 'flurry';
        output    = 'bin';
        main      = 'Main';
        codepaths = [ 'src' ];
    }
}

private class FlurryProjectBuild
{
    public var dependencies : Map<String, String>;

    public var macros : Array<String>;

    public var defines : Array<String>;

    public function new()
    {
        dependencies = [];
        macros       = [];
        defines      = [];
    }
}
