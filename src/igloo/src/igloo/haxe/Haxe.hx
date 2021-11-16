package igloo.haxe;

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

    // For cppia disable all dce to prevent classes getting removed which scripts depend on.
    hxml.dce = if (_release) full else std;

    // Remove traces and strip hxcpp debug output from generated sources in release mode.
    if (_release)
    {
        hxml.noTraces();
        hxml.addDefine('no-debug');
    }
    else
    {
        hxml.debug();
    }

    hxml.addDefine(getHostPlatformName());
    hxml.addDefine('HXCPP_M64');
    hxml.addDefine('HAXE_OUTPUT_FILE', _project.app.name);
    hxml.addDefine('flurry-entry-point', _project.app.main);
    hxml.addDefine('flurry-build-file', _projectPath.toString());
    hxml.addDefine('flurry-gpu-api', _graphicsBackend);

    hxml.addMacro('Safety.safeNavigation("uk.aidanlee.flurry")');
    hxml.addMacro('nullSafety("uk.aidanlee.flurry.modules", Strict)');
    hxml.addMacro('nullSafety("uk.aidanlee.flurry.api", Strict)');

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