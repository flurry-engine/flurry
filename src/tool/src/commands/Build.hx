package commands;

import uk.aidanlee.flurry.api.core.Result;
import Types.BuiltHost;
import Types.Project;
import Types.GraphicsBackend;
import tink.Cli;
import tink.Json;
import parcel.Packer;
import sys.io.abstractions.concrete.FileSystem;
import sys.io.abstractions.IFileSystem;
import haxe.io.Path;
import uk.aidanlee.flurry.api.core.Log;

using Utils;
using Safety;

class Build
{
    /**
     * If set will attempt to download all haxe and tool dependencies.
     * The build will fail if it can't download the files.
     */
    @:flag('restore')
    @:alias('p')
    public var restore = false;

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
     * Build and run the project with cppia.
     * Offers much faster build times at the cost of performance than standard desktop compilation.
     */
    @:flag('cppia')
    @:alias('s')
    public var cppia = false;

    /**
     * Forces the cppia host to be rebuilt. This will only do something if `--cppia` is also use.
     */
    @:flag('rebuild-host')
    @:alias('y')
    public var rebuildHost = false;

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
        Log.log('Build', Success);
        Log.log(Cli.getDoc(this), Info);
    }

    /**
     * The build command will take your code and assets and compile them into a runnable executable for the specified target.
     * It can optionally launch the executable on successfully building.
     */
    @:defaultCommand public function build()
    {
        final projectPath = sys.FileSystem.absolutePath(buildFile);
        final project     = parseProject(buildFile);
        final toolPath    = project.toolPath();
        final buildPath   = project.buildPath();
        final releasePath = project.releasePath();

        // Restore the project.
        if (needsRestore(project))
        {
            switch new Restore(project, fs, net, proc).run()
            {
                case Failure(_message): panic(_message);
                case _:
            }   
        }

        // Ensure our base directories are created.
        if (shouldClean(project))
        {
            fs.directory.remove(buildPath);
            fs.directory.remove(releasePath);
        }

        fs.directory.create(buildPath);
        fs.directory.create(releasePath);

        var buildResult  = Failure('not done');
        var parcelResult = Failure('not done');
        var buildDone  = false;
        var parcelDone = false;

        final lock = new sys.thread.Mutex();
        final gpu  = verifyGraphicsBackend(graphicsBackend);

        //
        sys.thread.Thread.create(() -> {
            // Generate a host and cppia script

            if (shouldGenerateHost(project, gpu))
            {
                Log.log('Generating Flurry Host', Success);
                final hxmlPath = Path.join([ buildPath, 'build-host.hxml' ]);
                final hxmlData = generateHostHxml(project, projectPath, gpu);
                fs.file.writeText(hxmlPath, hxmlData);

                switch buildResult = proc.run('npx', [ 'haxe', hxmlPath ], true)
                {
                    case Success(_):
                        if (cppia)
                        {
                            // Write info about the built host so future builds don't have to re-compile it.
                            final host = { gpu : gpu, entry : project.app.main, modules : new Array<String>() };
                            final path = Path.join([ project.buildPath(), 'cpp', 'host.json' ]);

                            fs.file.writeText(path, Json.stringify(host));
                        }
                        else
                        {
                            // If a file describing a cppia host exists remove it.
                            // This will force the host to be recompiled next time a cppia build is requested.
                            final path = Path.join([ project.buildPath(), 'cpp', 'host.json' ]);

                            if (fs.file.exists(path))
                            {
                                fs.file.remove(path);
                            }
                        }
                    case Failure(_):
                        lock.acquire();
                        buildDone = true;
                        lock.release();

                        // Exit early so client building won't potentially overwrite a host building failure
                        return;
                }
            }
            else
            {
                Log.log('Host Already Exists', Success);
            }

            // Only in cppia mode do we want to generate a cppia script and copy it over
            // Otherwise the "host" will contain everything compiled to native.
            if (cppia)
            {
                Log.log('Generating Flurry Client', Success);
                final hxmlPath = Path.join([ buildPath, 'build-client.hxml' ]);
                final hxmlData = generateClientHxml(project, projectPath);
                fs.file.writeText(hxmlPath, hxmlData);

                switch buildResult = proc.run('npx', [ 'haxe', hxmlPath ], true)
                {
                    case Failure(_):
                        lock.acquire();
                        buildDone = true;
                        lock.release();

                        return;
                    case _:
                        //
                }

                // Copy the cppia script over
                final debugScripts   = Path.join([ buildPath, 'cpp', 'assets', 'scripts' ]);
                final releaseScripts = Path.join([ releasePath, 'assets', 'scripts' ]);
                final cppiaScript    = Path.join([ project.buildPath(), 'cpp', 'client.cppia' ]);

                fs.directory.create(debugScripts);
                fs.directory.create(releaseScripts);

                fs.file.copy(cppiaScript, Path.join([ debugScripts, 'client.cppia' ]));
                fs.file.copy(cppiaScript, Path.join([ releaseScripts, 'client.cppia' ]));
            }

            lock.acquire();
            buildDone = true;
            lock.release();
        });

        //
        sys.thread.Thread.create(() -> {
            // Generate all parcels
            Log.log('Generating Parcels', Success);

            final debugParcels   = Path.join([ buildPath, 'cpp', 'assets', 'parcels' ]);
            final releaseParcels = Path.join([ releasePath, 'assets', 'parcels' ]);
            final packer         = new Packer(project, verbose, gpu, fs, proc);

            fs.directory.create(debugParcels);
            fs.directory.create(releaseParcels);

            for (assets in project!.parcels.or([]))
            {
                switch parcelResult = packer.create(assets)
                {
                    case Success(parcels):
                        for (parcel in parcels)
                        {
                            fs.file.copy(parcel.file, Path.join([ debugParcels, parcel.name ]));
                            fs.file.copy(parcel.file, Path.join([ releaseParcels, parcel.name ]));
                        }
                    case Failure(_):
                        lock.acquire();
                        parcelDone = true;
                        lock.release();

                        return;
                }
            }

            lock.acquire();
            parcelDone = true;
            lock.release();
        });

        var waiting = true;
        while (waiting)
        {
            Sys.sleep(0.1);

            if (lock.tryAcquire())
            {
                if (buildDone && parcelDone)
                {
                    waiting = false;
                }

                lock.release();
            }
        }

        switch buildResult
        {
            case Success(_data):
                //
            case Failure(_data):
                panic(_data);
        }
        switch parcelResult
        {
            case Success(_data):
                //
            case Failure(_data):
                panic(_data);
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
            Log.log('Copying Globbed Files', Success);

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
            Log.log('Running Project', Success);

            proc.run(project.executable(), [], true);
        }

        Log.log('Building Completed', Success);
    }

    /**
     * Log the provided string as an error and exit with a non zero return code.
     * @param _error Error message to log.
     */
    static function panic(_error : String)
    {
        Log.log(_error, Error);
        Sys.exit(1);
    }

    /**
     * Parse the json string at the provided file location.
     */
    function parseProject(_file : String) : Project
    {
        return Json.parse(fs.file.getText(_file));
    }

    /**
     * Parse the graphics backend string into its enum equivilent.
     */
    function verifyGraphicsBackend(_api : String) : GraphicsBackend
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
     * The build output not only needs to be cleaned if the clean flag is used but also when switching between
     * cppia and entirely native builds to avoid weird linking / cached object issues.
     * @param _project The project definition.
     * @param _fs File system object.
     * @param _clean If the clean flag was set
     * @param _cppia If a cppia build was requested.
     */
    function shouldClean(_project : Project)
    {
        if (clean)
        {
            return true;
        }

        final hostFile = Path.join([ _project.buildPath(), 'cpp', 'host.json' ]);

        // If the host file exists and we're not building for cppia force a clean.
        // This will ensure we don't run into any linking / caching issues.
        if (!cppia && fs.file.exists(hostFile))
        {
            return true;
        }

        // Similar to above except inverted.
        if (cppia && !fs.file.exists(hostFile))
        {
            return true;
        }

        return false;
    }

    /**
     * When building for cppia most of the time the host does not need to be recompiled.
     * This function checks if we're building with cppia and if a host definition file exists.
     * The definition file is a json file with some info about the currently existing host.
     * If the current host doesn't match the project we'll need to re-compile it.
     * @param _project The project to build.
     * @param _fs File system object.
     * @param _gpu The graphics API specified.
     * @param _cppia If we are building for cppia.
     * @param _rebuild If the host has been forced to be rebuild.
     */
    function shouldGenerateHost(_project : Project, _gpu : GraphicsBackend)
    {
        return if (!cppia || rebuildHost)
        {
            true;
        }
        else
        {
            final hostFile = Path.join([ _project.buildPath(), 'cpp', 'host.json' ]);
            if (fs.file.exists(hostFile))
            {
                final builtHost : BuiltHost = Json.parse(fs.file.getText(hostFile));
                
                builtHost.gpu != _gpu || builtHost.entry != _project.app.main;
            }
            else
            {
                true;
            }
        }
    }

    function needsRestore(_project : Project)
    {
        if (restore)
        {
            return true;
        }

        final toolPath  = _project.toolPath();
        final msdfTool  = Path.join([ toolPath, Utils.msdfAtlasExecutable() ]);
        final atlasTool = Path.join([ toolPath, Utils.atlasCreatorExecutable() ]);
        final glslTool  = Path.join([ toolPath, Utils.glslangExecutable() ]);
        final sprivTool = Path.join([ toolPath, Utils.spirvCrossExecutable() ]);

        return
            !fs.file.exists(msdfTool) ||
            !fs.file.exists(atlasTool) ||
            !fs.file.exists(glslTool) ||
            !fs.file.exists(sprivTool);
    }

    /**
     * Generates a hxml file for the given project.
     * @param _project Project.
     * @param _projectPath Absolute path to project file.
     * @param _release If the project is to be built in release mode.
     * @param _gpu Graphics api to build with.
     * @return String
     */
    function generateHostHxml(_project : Project, _projectPath : String, _gpu : GraphicsBackend) : String
    {
        final hxml = new Hxml();

        hxml.main = 'uk.aidanlee.flurry.hosts.SDLHost';
        hxml.cpp  = Path.join([ _project.buildPath(), 'cpp' ]);
        hxml.dce  = no;

        if (_project!.build!.profile.or(Debug) == Release || release)
        {
            hxml.noTraces();
            hxml.addDefine('no-debug');
        }
        else
        {
            hxml.debug();
        }

        hxml.addDefine(Utils.platform());
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

        if (cppia)
        {
            hxml.addDefine('scriptable');
            hxml.addDefine('flurry-cppia');
            hxml.addDefine('flurry-cppia-script', Path.join([ 'assets', 'scripts', 'client.cppia' ]));
            hxml.addDefine('dll_export', Path.join([ _project.buildPath(), 'cpp', 'host_classes.info' ]));
            hxml.addMacro('include("uk.aidanlee.flurry.api")');
            hxml.addMacro('include("uk.aidanlee.flurry.module")');
            hxml.addMacro('include("haxe.ds")');
            hxml.addMacro('keep("haxe.ds.Vector")');
        }

        return hxml.toString();
    }

    /**
     * The cppia client hxml is very similar to the host but doesn't specify a main.
     * Instead we specify the Main class and make sure its included.
     * @param _project Project.
     * @param _projectPath Absolute path to project file.
     * @param _release If the project is to be built in release mode.
     */
    function generateClientHxml(_project : Project, _projectPath : String)
    {
        final hxml = new Hxml();

        hxml.include = _project.app.main;
        hxml.cppia   = Path.join([ _project.buildPath(), 'cpp', 'client.cppia' ]);
        hxml.dce     = std;

        if (_project!.build!.profile.or(Debug) == Release || release)
        {
            hxml.noTraces();
            hxml.addDefine('no-debug');
        }
        else
        {
            hxml.debug();
        }

        hxml.addDefine(Utils.platform());
        hxml.addDefine('scriptable');
        hxml.addDefine('HXCPP_M64');
        hxml.addDefine('flurry-entry-point', _project.app.main);
        hxml.addDefine('flurry-gpu-api', 'mock');
        hxml.addDefine('dll_import', Path.join([ _project.buildPath(), 'cpp', 'host_classes.info' ]));
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

        hxml.addMacro('keep("${ _project.app.main }")');

        return hxml.toString();
    }
}