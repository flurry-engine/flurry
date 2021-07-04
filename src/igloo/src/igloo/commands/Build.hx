package igloo.commands;

import igloo.utils.Concurrency;
import igloo.processors.ProcessorLoadResults.ProcessorLoadResult;
import hx.files.File.FileCopyOption;
import hx.files.Dir;
import igloo.utils.GraphicsApi;
import igloo.haxe.Haxe;
import igloo.macros.Platform;
import hx.concurrent.executor.Executor;
import igloo.tools.ToolsFetcher;
import haxe.Exception;
import hx.files.Path;
import igloo.macros.BuildPaths;
import igloo.parcels.Package;
import igloo.parcels.Builder;
import igloo.parcels.ParcelContext;
import igloo.project.Project;
import igloo.processors.Cache;
import igloo.processors.AssetProcessor;
import json2object.ErrorUtils;
import json2object.JsonParser;

class Build
{
    final packageParser : JsonParser<Package>;

    final projectParser : JsonParser<Project>;

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
    public var graphicsBackend : GraphicsApi = 'auto';

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

    public function new()
    {
        projectParser = new JsonParser<Project>();
        packageParser = new JsonParser<Package>();
    }

    @:defaultCommand
    public function execute()
    {
        Console.log('Igloo v0.1');

        final projectPath = getBuildFilePath();
        final project     = projectParser.fromJson(projectPath.toFile().readAsString());

        if (projectParser.errors.length > 0)
        {
            throw new Exception(ErrorUtils.convertErrorArray(projectParser.errors));
        }

        final outputDir  = projectPath.parent.join(project.app.output);
        final executor   = Executor.create(Concurrency.hardwareConcurrency());
        final tools      = fetchTools(outputDir);
        final processors = loadProjectProcessors(executor, projectPath.parent, project);

        // The .build directory will contain all the generated sources and intermediate cpp objects.
        // The final directory is just the final application, parcels, and copied files.
        final buildDir = outputDir.joinAll([ '${ getHostPlatformName() }.build', 'cpp' ]);
        final finalDir = outputDir.join(getHostPlatformName());

        buildDir.toDir().create();
        finalDir.toDir().create();

        // Building Code

        if (hostNeedsGenerating(buildDir, graphicsBackend, project.app.main, cppia, rebuildHost))
        {
            final hxmlPath = buildDir.parent.join('build-host.hxml');
            final hxmlData = generateHostHxml(project, cppia, release, graphicsBackend, projectPath, buildDir);

            hxmlPath.toFile().writeString(hxmlData);

            if (Sys.command('npx', [ 'haxe', hxmlPath.toString() ]) != 0)
            {
                Sys.exit(-1);
            }

            if (cppia)
            {
                writeHostMeta(buildDir, graphicsBackend, project.app.main);
            }
            else
            {
                buildDir.join('host.json').toFile().delete();
            }
        }

        if (cppia)
        {
            final hxmlPath = buildDir.parent.join('build-client.hxml');
            final hxmlData = generateClientHxml(project, projectPath, release, buildDir);

            hxmlPath.toFile().writeString(hxmlData);

            if (Sys.command('npx', [ 'haxe', hxmlPath.toString() ]) != 0)
            {
                Console.error('Failed to compile project');

                Sys.exit(-1);
            }

            final script      = buildDir.join('client.cppia').toFile();
            final buildScript = buildDir.joinAll([ 'assets', 'client.cppia' ]);
            final finalScript = finalDir.joinAll([ 'assets', 'client.cppia' ]);

            buildScript.parent.toDir().create();
            finalScript.parent.toDir().create();

            script.copyTo(buildScript, [ FileCopyOption.OVERWRITE ]);
            script.copyTo(finalScript, [ FileCopyOption.OVERWRITE ]);
        }

        // Building Assets

        for (bundlePath in project.parcels)
        {
            final parcelPath   = projectPath.parent.join(bundlePath);
            final baseAssetDir = parcelPath.parent;
            final bundle       = packageParser.fromJson(parcelPath.toFile().readAsString());

            if (packageParser.errors.length > 0)
            {
                throw new Exception(ErrorUtils.convertErrorArray(packageParser.errors));
            }

            for (parcel in bundle.parcels)
            {
                Console.log('Building ${ parcel.name }');

                final tempOutput   = outputDir.joinAll([ 'tmp', parcel.name ]);
                final parcelCache  = outputDir.joinAll([ 'cache', 'parcels' ]);
                final context      = new ParcelContext(
                    baseAssetDir,
                    tempOutput,
                    parcelCache,
                    graphicsBackend,
                    tools,
                    executor);

                tempOutput.toDir().create();
                parcelCache.toDir().create();

                // Build and copy over the parcel
                // Copy to the cpp build directory as well, this allows us to load the exe into visual studio
                // for debugging without manually copying files

                final parcelPath      = build(context, parcel, bundle.assets, processors, graphicsBackend);
                final parcelBuildPath = buildDir.joinAll([ 'assets', parcelPath.filename ]);
                final parcelFinalPath = finalDir.joinAll([ 'assets', parcelPath.filename ]);

                parcelBuildPath.parent.toDir().create();
                parcelFinalPath.parent.toDir().create();

                parcelPath.toFile().copyTo(parcelBuildPath, [ FileCopyOption.OVERWRITE ]);
                parcelPath.toFile().copyTo(parcelFinalPath, [ FileCopyOption.OVERWRITE ]);

                tempOutput.toDir().delete(true);
            }
        }

        // Copy over the executable

        switch getHostPlatformName()
        {
            case 'windows':
                final src = buildDir.join('${ project.app.name }.exe');
                final dst = finalDir.join('${ project.app.name }.exe');

                src.toFile().copyTo(dst, [ FileCopyOption.OVERWRITE ]);
            default:
                final src = buildDir.join(project.app.name);
                final dst = finalDir.join(project.app.name);

                src.toFile().copyTo(dst, [ FileCopyOption.OVERWRITE ]);

                if (Sys.command('chmod', [ 'a+x', src.toString() ]) != 0)
                {
                    throw new Exception('Failed to set the project output as executable');
                }
                if (Sys.command('chmod', [ 'a+x', dst.toString() ]) != 0)
                {
                    throw new Exception('Failed to set the project output as executable');
                }
        }

        // Copy over file globs.

        for (glob => dst in project.build.files)
        {
            final path = Path.of(glob);

            if (path.exists())
            {
                // Not a glob file, just copy it over.
                // If the dst if an empty string re-use the source file name.
                // destination paths are relative to the produced exe.
                final output = if (dst == '') path.filename else dst;

                path.toFile().copyTo(buildDir.join(output), [ FileCopyOption.OVERWRITE ]);
                path.toFile().copyTo(finalDir.join(output), [ FileCopyOption.OVERWRITE ]);
            }
            else
            {
                Console.warn('Glob copying is not yet implemented');

                // final dir = if (path.isAbsolute)
                // {
                //     final endIdx = glob.indexOf('*');
                //     final subStr = glob.substring(0, endIdx);
    
                //     Dir.of(subStr);
                // }
                // else
                // {
                //     projectPath.parent.toDir();
                // }
    
                // for (file in dir.findFiles(glob))
                // {
                //     trace(file);
                // }
            }
        }

        // Potentially run the built project.

        if (run)
        {
            Sys.command(finalDir.join(project.app.name).toString());
        }
    }

    function getBuildFilePath()
    {
        final path = Path.of(buildFile);

        return if (path.isAbsolute)
        {
            path;
        }
        else
        {
            Path.of(path.getAbsolutePath());
        }
    }

    function loadProjectProcessors(_executor : Executor, _root : Path, _project : Project)
    {
        final cacheLoader = new Cache(_root.joinAll([ _project.app.output, 'cache', 'processors' ]));
        final loadResults = new ProcessorLoadResult();
        final tasks       = [];

        // Load default flurry processors
        getIglooBuiltInScriptsDir()
            .toDir()
            .walk(file -> {
                if (file.path.filenameExt == 'hx')
                {
                    final flagsPath = file.path.parent.join(file.path.filenameStem + '.flags');
                    final flagsText = if (flagsPath.exists()) flagsPath.toFile().readAsString() else '';
                    final task      = _executor.submit(() -> cacheLoader.load(file.path, flagsText));

                    tasks.push(task);
                }
            });

        // Load user processors
        for (request in _project.build.processors)
        {
            tasks.push(_executor.submit(() -> cacheLoader.load(_root.join(request.source), request.flags)));
        }

        // Process each task
        for (task in tasks)
        {
            switch task.waitAndGet(-1)
            {
                case SUCCESS(result, _, _):
                    loadResults.names.push(result.source.filenameStem);

                    for (id in result.processor.ids())
                    {
                        loadResults.loaded.set(id, result.processor);
                    }

                    if (result.wasRecompiled)
                    {
                        loadResults.recompiled.push(result.source.filenameStem);
                    }

                    task.cancel();
                case FAILURE(ex, _, _):
                    ex.rethrow();
                case NONE(_):
                    throw new Exception('Unexpected task result of NONE');
            }
        }

        return loadResults;
    }
}