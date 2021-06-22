package igloo.commands;

import igloo.tools.ToolsFetcher;
import haxe.Exception;
import hx.files.Path;
import igloo.macros.BuildPaths;
import igloo.parcels.Package;
import igloo.parcels.Builder;
import igloo.parcels.ParcelContext;
import igloo.project.Project;
import igloo.processors.Cache;
import igloo.processors.IAssetProcessor;
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

    public function new()
    {
        projectParser = new JsonParser<Project>();
        packageParser = new JsonParser<Package>();
    }

    @:defaultCommand
    public function execute()
    {
        final buildPath = getBuildFilePath();
        final project   = projectParser.fromJson(buildPath.toFile().readAsString());

        if (projectParser.errors.length > 0)
        {
            throw new Exception(ErrorUtils.convertErrorArray(projectParser.errors));
        }

        final outputDir  = buildPath.parent.join(project.app.output);
        final tools      = fetchTools(outputDir);
        final processors = loadProjectProcessors(buildPath.parent, project);

        for (bundlePath in project.parcels)
        {
            final parcelPath   = buildPath.parent.join(bundlePath);
            final baseAssetDir = parcelPath.parent;
            final bundle       = packageParser.fromJson(parcelPath.toFile().readAsString());

            if (packageParser.errors.length > 0)
            {
                throw new Exception(ErrorUtils.convertErrorArray(packageParser.errors));
            }

            for (parcel in bundle.parcels)
            {
                final tempOutput  = outputDir.joinAll([ 'tmp', parcel.name ]);
                final parcelCache = outputDir.joinAll([ 'cache', 'parcels', parcel.name ]);
                final context     = new ParcelContext(
                    baseAssetDir,
                    tempOutput,
                    parcelCache,
                    tools);

                tempOutput.toDir().create();
                parcelCache.toDir().create();

                build(context, parcel, bundle.assets, processors);
            }
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

    function loadProjectProcessors(_root : Path, _project : Project)
    {
        final cacheLoader      = new Cache(_root.joinAll([ _project.app.output, 'cache', 'processors' ]));
        final loadedProcessors = new Map();

        // Load default flurry processors
        getIglooBuiltInScriptsDir()
            .toDir()
            .walk(file -> {
                if (file.path.filenameExt == 'hx')
                {
                    final flagsPath = file.path.parent.join(file.path.filenameStem + '.flags');
                    final flagsText = if (flagsPath.exists()) flagsPath.toFile().readAsString() else '';

                    loadProcessorInto(cacheLoader, file.path, flagsText, loadedProcessors);
                }
            });

        // Load user processors
        for (request in _project.build.processors)
        {
            loadProcessorInto(cacheLoader, _root.join(request.source), request.flags, loadedProcessors);
        }

        return loadedProcessors;
    }

    function loadProcessorInto(_cache : Cache, _path : Path, _flags : String, _store : Map<String, IAssetProcessor<Any>>)
    {
        final obj = _cache.load(_path, _flags);

        for (id in obj.ids())
        {
            if (_store.exists(id))
            {
                Sys.println('WARNING: replacing existing processor with id : $id');
            }

            _store.set(id, obj);
        }
    }
}