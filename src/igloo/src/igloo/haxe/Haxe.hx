package igloo.haxe;

import json2object.JsonWriter;
import hx.files.Path;
import json2object.JsonParser;
import igloo.utils.GraphicsApi;
import igloo.macros.Platform;
import igloo.project.Project;

/**
 * Checks if the host program needs recompiling.
 * If cppia is not used then this always returns true, else it will attempt
 * to check the metadata file created when the host was built to check its still valid.
 * @param _buildPath Path to the folder where sources and intermediate objects are placed.
 * @param _graphicsBackend The graphics API selected.
 * @param _main The entry point class.
 * @param _cppia If cppia is used.
 * @param _rebuildHost If the user requested the host is rebuilt.
 */
function hostNeedsGenerating(_buildPath : Path, _graphicsBackend : GraphicsApi, _main : String, _cppia : Bool, _rebuildHost : Bool)
{
    return if (!_cppia || _rebuildHost)
    {
        true;
    }
    else
    {
        final parser   = new JsonParser<BuiltHost>();
        final hostPath = _buildPath.join('host.json');
        if (hostPath.exists())
        {
            final host = parser.fromJson(hostPath.toFile().readAsString());

            if (parser.errors.length > 0)
            {
                true;
            }
            else
            {
                host.gpu != _graphicsBackend || host.entry != _main;
            }
        }
        else
        {
            true;
        }
    }
}

/**
 * Writes a json file describing the built host executable.
 * @param _buildPath Directory to store the file in.
 * @param _graphicsBackend The graphics backend the host uses.
 * @param _main The entry point the host uses.
 */
function writeHostMeta(_buildPath : Path, _graphicsBackend : GraphicsApi, _main : String)
{
    final writer   = new JsonWriter<BuiltHost>();
    final host     = new BuiltHost(_graphicsBackend, _main);
    final hostPath = _buildPath.join('host.json');

    hostPath.toFile().writeString(writer.write(host));
}

/**
 * Generate a hxml file for a flurry host.
 * @param _project Project to generate a hxml file.
 * @param _cppia If cppia scripting is to be used for the client code.
 * @param _release If the host should be built without debug information.
 * @param _graphicsBackend Which graphics API the host should use.
 * @param _projectPath Location of the project file.
 * @param _output Directory to output the generated sources in.
 */
function generateHostHxml(_project : Project, _cppia : Bool, _release : Bool, _graphicsBackend : GraphicsApi, _projectPath : Path, _output : Path)
{
    final hxml = new Hxml();

    hxml.cpp  = _output.toString();
    hxml.main = switch _project.app.backend
    {
        case Sdl: 'uk.aidanlee.flurry.hosts.SDLHost';
        case Cli: 'uk.aidanlee.flurry.hosts.CLIHost';
    }
    // For cppia disable all dce to prevent classes getting removed which scripts depend on.
    hxml.dce = if (_cppia)
    {
        no;
    }
    else if (_release)
    {
        full;
    }
    else
    {
        std;
    }

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

    if (_cppia)
    {
        hxml.addDefine('scriptable');
        hxml.addDefine('flurry-cppia');
        hxml.addDefine('flurry-cppia-script', Path.of('assets/client.cppia').toString());
        hxml.addDefine('dll_export', _output.join('host_classes.info').toString());
        hxml.addMacro('include("uk.aidanlee.flurry.api")');
        hxml.addMacro('include("uk.aidanlee.flurry.module")');
        hxml.addMacro('include("haxe.ds")');
        hxml.addMacro('keep("haxe.ds.Vector")');
    }

    return hxml.toString();
}

/**
 * Generate a hxml which will produce a cppia script with the users project code.
 * @param _project Project to build the client script for.
 * @param _projectPath Path to the project file.
 * @param _release If the host should be built without debug information.
 * @param _output Directory to output the script in.
 */
function generateClientHxml(_project : Project, _projectPath : Path, _release : Bool, _output : Path)
{
    final hxml = new Hxml();

    hxml.include = _project.app.main;
    hxml.cppia   = _output.join('client.cppia').toString();
    hxml.dce     = std;

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

    hxml.addDefine('HXCPP_M64');
    hxml.addDefine('flurry-gpu-api', 'mock');
    hxml.addDefine('flurry-build-file', _projectPath.toString());
    hxml.addDefine('dll_import', _output.join('host_classes.info').toString());
    hxml.addMacro('Safety.safeNavigation("uk.aidanlee.flurry")');
    hxml.addMacro('nullSafety("uk.aidanlee.flurry.modules", Strict)');
    hxml.addMacro('nullSafety("uk.aidanlee.flurry.api", Strict)');

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

    hxml.addMacro('keep("${ _project.app.main }")');

    return hxml.toString();
}