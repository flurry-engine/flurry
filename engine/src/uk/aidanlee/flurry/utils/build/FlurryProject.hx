package uk.aidanlee.flurry.utils.build;

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

        var hxml = new HXML();
        var snow = new HXML();
        addSnowSettings(hxml, snow);
        addUserSettings(hxml);

        writeSnowBuildFiles(hxml, snow);
    }

    function setup()
    {
        //
    }

    final function addSnowSettings(_hxml : HXML, _snow : HXML)
    {
        _hxml.main = 'snow.App';
        _hxml.cpp  = Path.combine(app.output, 'cpp');

        _hxml.define('linux');
        _hxml.define('target-cpp');
        _hxml.define('arch-64');
        _hxml.define('desktop');
        _hxml.define('hxcpp_static_std');

        _hxml.define('snow_use_glew');
        _hxml.define('snow_native');
        _hxml.define('snow');

        _hxml.lib('hxcpp'          , null);
        _hxml.lib('haxe-concurrent', null);
        _hxml.lib('linc_opengl'    , null);
        _hxml.lib('linc_directx'   , null);
        _hxml.lib('linc_sdl'       , null);
        _hxml.lib('linc_ogg'       , null);
        _hxml.lib('linc_stb'       , null);
        _hxml.lib('linc_timestamp' , null);
        _hxml.lib('linc_openal'    , null);
        _hxml.lib('snow'           , null);

        _hxml.addMacro('snow.Set.assets("snow.core.native.assets.Assets")');
        _hxml.addMacro('snow.Set.runtime("snow.modules.sdl.Runtime")');
        _hxml.addMacro('snow.Set.audio("snow.modules.openal.Audio")');
        _hxml.addMacro('snow.Set.io("snow.modules.sdl.IO")');

        _snow.addMacro('snow.Set.main("${app.main}")');
        _snow.addMacro('snow.Set.ident("${app.namespace}")');
        _snow.addMacro('snow.Set.config("config.json")');
        _snow.addMacro('snow.Set.runtime("uk.aidanlee.flurry.utils.runtimes.FlurryRuntimeDesktop")');
    
    }

    final function addUserSettings(_hxml : HXML)
    {
        for (codepath in app.codepaths)
        {
            _hxml.cp(codepath);
        }

        for (define in build.defines)
        {
            _hxml.define(define);
        }

        for (lib => ver in build.dependencies)
        {
            _hxml.lib(lib, ver);
        }

        for (mac in build.macros)
        {
            _hxml.addMacro(mac);
        }

        for (res in build.resources)
        {
            _hxml.resource(res);
        }

        for (src => dst in files)
        {
            System.recursiveCopy(src, Path.combine(_hxml.cpp, dst));
        }
    }

    final function writeSnowBuildFiles(_hxml : HXML, _snow : HXML)
    {
        var build = File.write(Path.combine(app.output, 'build.hxml'), false);
        var snow  = File.write(Path.combine(app.output, 'snow.hxml'), false);

        build.writeString(_hxml);
        build.writeString('\n');
        build.writeString(Path.combine(app.output, 'snow.hxml'));

        snow.writeString(_snow);

        build.close();
        snow.close();
    }
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
        output    = 'bin/flurry';
        main      = 'Main';
        codepaths = [ 'src' ];
    }
}

private class FlurryProjectBuild
{
    public var dependencies : Map<String, String>;

    public var macros : Array<String>;

    public var resources : Array<String>;

    public var defines : Array<String>;

    public function new()
    {
        dependencies = [];
        macros       = [];
        resources    = [];
        defines      = [];
    }
}
