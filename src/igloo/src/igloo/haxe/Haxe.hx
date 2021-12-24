package igloo.haxe;

import igloo.macros.BuildPaths;
import hx.files.Path;
import igloo.utils.GraphicsApi;
import igloo.macros.Platform;
import igloo.project.Project;
import igloo.parcels.LoadedParcel;

using hx.strings.Strings;

/**
 * Generate a hxml file for a flurry host.
 * @param _project Project to generate a hxml file.
 * @param _parcels All parcels packaged for this project.
 * @param _release If the host should be built without debug information.
 * @param _graphicsBackend Which graphics API the host should use.
 * @param _projectPath Location of the project file.
 * @param _output Directory to output the generated sources in.
 */
function generateHostHxml(_project : Project, _parcels : Array<LoadedParcel>, _release : Bool, _graphicsBackend : GraphicsApi, _projectPath : Path, _output : Path)
{
    final hxml = new Hxml();

    hxml.cpp  = _output.toString();
    hxml.main = switch _project.app.backend
    {
        case Sdl: 'uk.aidanlee.flurry.hosts.SDLHost';
        case Cli: 'uk.aidanlee.flurry.hosts.CLIHost';
    }

    // Remove traces and strip hxcpp debug output from generated sources in release mode.
    if (_release)
    {
        hxml.noTraces();
        hxml.addDefine('no-debug');
        hxml.dce = full;
    }
    else
    {
        hxml.debug();
    }

    // Default Settings.

    hxml.addDefine(getHostPlatformName());
    hxml.addDefine('HXCPP_M64');
    hxml.addDefine('HAXE_OUTPUT_FILE', _project.app.name);
    hxml.addDefine('flurry-entry-point', _project.app.main);
    hxml.addDefine('flurry-build-file', _projectPath.toString());
    hxml.addDefine('flurry-gpu-api', _graphicsBackend);

    hxml.addMacro('Safety.safeNavigation("uk.aidanlee.flurry")');
    hxml.addMacro('nullSafety("uk.aidanlee.flurry.modules", Strict)');
    hxml.addMacro('nullSafety("uk.aidanlee.flurry.api", Strict)');

    hxml.addLibrary('haxe-files');
    hxml.addLibrary('haxe-concurrent');
    hxml.addLibrary('hxrx');
    hxml.addLibrary('safety');
    hxml.addLibrary('vector-math');
    hxml.addLibrary('linc_sdl');
    hxml.addLibrary('linc_stb');
    hxml.addLibrary('linc_imgui');

    switch _graphicsBackend
    {
        case Mock:
            //
        case Ogl3:
            hxml.addLibrary('linc_opengl');
        case D3d11:
            hxml.addLibrary('linc_directx');
    }

    hxml.addClassPath(getFlurryLibSrcPath().toString());

    // Project Settings.

    for (parcel in _parcels)
    {
        hxml.addMacro('uk.aidanlee.flurry.macros.Parcels.loadParcelMeta("${ parcel.parcel.name }", "${ haxe.io.Path.normalize(parcel.parcelMeta.toString()) }")');
    }

    for (p in _project.app.codepaths)
    {
        hxml.addClassPath(p);
    }

    for (d in _project.build.defines)
    {
        hxml.addDefine(d.def, d.value);
    }

    for (m in _project.build.macros)
    {
        hxml.addMacro(m);
    }

    for (d in _project.build.dependencies)
    {
        hxml.addLibrary(d);
    }

    return hxml.toString();
}

function generateScriptsHxml(_project : Project, _projectPath : Path)
{
    final paths = [ getIglooCodePath().toString() ];
    final flags = [];
    final hxml  = new Hxml();

    for (proc in _project.build.processors)
    {
        final path = _projectPath.join(proc.source);

        if (!Lambda.exists(paths, p -> path.toString() == p))
        {
            paths.push(path.toString());
            flags.push(proc.flags);
        }
    }

    for (p in paths)
    {
        hxml.addClassPath(p);
    }

    for (f in flags)
    {
        hxml.append(f);
    }

    hxml.cppia = 'dummy.cppia';

    return hxml.toString();
}