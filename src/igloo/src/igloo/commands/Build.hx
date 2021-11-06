package igloo.commands;

import haxe.io.Bytes;
import sys.io.Process;
import haxe.Exception;
import igloo.haxe.Haxe;
import igloo.utils.Concurrency;
import igloo.utils.GraphicsApi;
import igloo.tools.ToolsFetcher;
import igloo.logger.Log;
import igloo.logger.LogLevel;
import igloo.logger.LogConfig;
import igloo.macros.Platform;
import igloo.macros.BuildPaths;
import igloo.parcels.Builder;
import igloo.project.Project;
import igloo.parcels.ParcelContext;
import igloo.parcels.ParcelResolver;
import igloo.processors.Cache;
import igloo.processors.ProcessorLoadResults;
import hx.files.Path;
import hx.files.File.FileCopyOption;
import hx.concurrent.executor.Executor;
import json2object.ErrorUtils;
import json2object.JsonParser;

using Lambda;

class Build
{
    final projectParser : JsonParser<Project>;

    final id : Int;

    final root : Log;

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

    @:flag('log')
    @:alias('l')
    public var log : LogLevel = 'INF';

    /**
     * Target to build the project to.
     * Can be any of the following.
     * - `desktop` - Build the project as a native executable for the host operating system.
     */
    @:flag('target')
    @:alias('t')
    public var target = 'desktop';

    /**
     * Forces the cppia host to be rebuilt. This will only do something if `--cppia` is also use.
     */
    @:flag('rebuild-host')
    @:alias('y')
    public var rebuildHost = false;

    public function new(_id, _log)
    {
        id            = _id;
        root          = _log;
        projectParser = new JsonParser<Project>();
    }

    @:command
    public function help()
    {
        Sys.println(tink.Cli.getDoc(this));
    }

    @:defaultCommand
    public function execute()
    {
        final logger =
            new LogConfig()
                .setMinimumLevel(log)
                .writeTo(root)
                .enrichWith('command', 'build')
                .create();

        logger.info('Igloo v0.1');

        final projectPath = getBuildFilePath();
        final project     = projectParser.fromJson(projectPath.toFile().readAsString());

        if (projectParser.errors.length > 0)
        {
            throw new Exception('Failed to parse project file ${ projectPath.toString() }', new Exception(ErrorUtils.convertErrorArray(projectParser.errors)));
        }

        final outputDir  = projectPath.parent.join(project.app.output);
        final executor   = Executor.create(Concurrency.hardwareConcurrency());
        final tools      = fetchTools(outputDir, logger);
        final processors = loadProjectProcessors(logger, executor, projectPath.parent, project);

        // The .build directory will contain all the generated sources and intermediate cpp objects.
        // The final directory is just the final application, parcels, and copied files.
        final buildDir = outputDir.joinAll([ '${ getHostPlatformName() }.build', 'cpp' ]);
        final finalDir = outputDir.join(getHostPlatformName());

        buildDir.toDir().create();
        finalDir.toDir().create();

        // Building Assets

        final parcels    = resolveParcels(projectPath, logger, project.parcels, outputDir, id, graphicsBackend, release, processors);
        final idProvider = createIDProvider(logger, parcels);

        var someParcelsPackage = false;
        for (loaded in parcels)
        {
            if (!loaded.validCache)
            {
                try
                {
                    loaded.tempDir.toDir().create();
                    loaded.cacheDir.toDir().create();

                    final ctx = new ParcelContext(
                        loaded.parcel.name,
                        loaded.assetDir,
                        loaded.tempDir,
                        loaded.cacheDir,
                        graphicsBackend,
                        release,
                        tools,
                        executor);
    
                    build(ctx, logger, id, loaded, processors, idProvider);

                    someParcelsPackage = true;
                }
                catch (e)
                {
                    // TODO : Cleanup tmp and cache then rethrow
                    // This ensure we cleanup any in-process packing.

                    // parcel.cacheDir.toDir().delete(true);
                    // parcel.tempDir.toDir().delete(true);

                    throw new Exception('Failed to package ${ loaded.parcel.name }', e);
                }
            }

            final parcelBuildPath = buildDir.joinAll([ 'assets', loaded.parcelFile.filename ]);
            final parcelFinalPath = finalDir.joinAll([ 'assets', loaded.parcelFile.filename ]);

            parcelBuildPath.parent.toDir().create();
            parcelFinalPath.parent.toDir().create();

            loaded.parcelFile.toFile().copyTo(parcelBuildPath, [ FileCopyOption.OVERWRITE ]);
            loaded.parcelFile.toFile().copyTo(parcelFinalPath, [ FileCopyOption.OVERWRITE ]);
            loaded.tempDir.toDir().delete(true);
        }

        // Building Code

        final hxmlPath = buildDir.parent.join('build-host.hxml');
        final hxmlData = generateHostHxml(project, parcels, release, graphicsBackend, projectPath, buildDir);

        hxmlPath.toFile().writeString(hxmlData);

        final haxeProc = new Process('npx haxe D:/projects/flurry/flurry/tests/system/bin/windows.build/build-host.hxml');
        final haxeLog  = new LogConfig()
            .setMinimumLevel(log)
            .writeTo(logger)
            .enrichWith('stage', 'haxe')
            .create();

        var code : Null<Int> = null;
        while (null == (code = haxeProc.exitCode(false)))
        {
            try
            {
                haxeLog.info('${ stdout }', haxeProc.stdout.readLine());
            }
            catch (e)
            {
                // potential EoF exception from stdout
            }
        }

        switch code
        {
            case 0:
                haxeLog.info('haxe compilation succeeded');

                // Copy over the executable

                switch getHostPlatformName()
                {
                    case 'windows':
                        final src = buildDir.join('${ project.app.name }.exe');
                        final dst = finalDir.join('${ project.app.name }.exe');

                        haxeLog.verbose('copying exe from $src to $dst');

                        src.toFile().copyTo(dst, [ FileCopyOption.OVERWRITE ]);
                    default:
                        final src = buildDir.join(project.app.name);
                        final dst = finalDir.join(project.app.name);

                        haxeLog.verbose('copying exe from $src to $dst');

                        src.toFile().copyTo(dst, [ FileCopyOption.OVERWRITE ]);

                        switch Sys.command('chmod', [ 'a+x', src.toString() ])
                        {
                            case code if (code != 0):
                                haxeLog.error('Failed to set the executable bit of $src, chmod returned $code');
                            case _:
                                haxeLog.verbose('Set the executable bit of $src');
                        }
                        switch Sys.command('chmod', [ 'a+x', dst.toString() ])
                        {
                            case code if (code != 0):
                                haxeLog.error('Failed to set the executable bit of $dst, chmod returned $code');
                            case _:
                                haxeLog.verbose('Set the executable bit of $dst');
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
                        haxeLog.info('Glob copying is not yet implemented');
                    }
                }

                // Potentially run the built project.

                if (run)
                {
                    Sys.command(finalDir.join(project.app.name).toString());
                }
            case _:
                final stderr = try haxeProc.stderr.readAll().toString() catch (_) '';

                haxeLog.error('haxe compilation failed $stderr');
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

    function loadProjectProcessors(_log : Log, _executor : Executor, _root : Path, _project : Project)
    {
        final processorDir = _root.joinAll([ _project.app.output, 'cache', 'processors' ]);
        final cacheLoader  = new Cache(processorDir);
        final loadResults  = new ProcessorLoadResult();
        final tasks        = [];

        // cppia compilation will fail if the output directory doesn't exist, ensure it does.
        processorDir.toDir().create();

        // Load default flurry processors
        getIglooBuiltInScriptsDir()
            .toDir()
            .walk(file -> {
                if (file.path.filenameExt == 'hx')
                {
                    final flagsPath = file.path.parent.join(file.path.filenameStem + '.flags');
                    final flagsText = if (flagsPath.exists()) flagsPath.toFile().readAsString() else '';
                    final task      = _executor.submit(() -> cacheLoader.load(_log, file.path, flagsText));

                    tasks.push(task);
                }
            });

        // Load user processors
        for (request in _project.build.processors)
        {
            tasks.push(_executor.submit(() -> cacheLoader.load(_log, _root.join(request.source), request.flags)));
        }

        // Process each task
        var failureCount = 0;

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
                    _log.error('failed to compile script ${ exception }', ex.toString());

                    failureCount++;
                case NONE(_):
                    throw new Exception('Unexpected future result of NONE');
            }
        }

        return if (failureCount > 0)
        {
            throw new Exception('Some scripts failed to compile');
        }
        else
        {
            loadResults;
        }
    }
}