package commands;

import Types.Project;
import tink.Cli;
import tink.Json;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;
import haxe.io.Path;
import parcel.Types.JsonDefinition;

using Safety;

class Create
{
    /**
     * Name of the project and output executable.
     */
    public var name = 'Project';

    /**
     * Main class name.
     */
    public var main = 'Main';

    /**
     * Main folder code will be stored in.
     */
    public var codepath = 'src';

    /**
     * Project output directory.
     */
    public var output = 'bin';

    /**
     * Creator of the project.
     */
    public var author = 'Flurry';

    /**
     * Main folder assets will be stored in.
     */
    public var resources = 'assets';

    final fs : IFileSystem;

    final assets : JsonDefinition;

    public function new(_fs : IFileSystem = null)
    {
        fs     = _fs.or(new FileSystem());
        assets = {
            assets : {
                bytes   : [],
                shaders : [],
                sheets  : [],
                sprites : [],
                images  : [],
                fonts   : [],
                texts   : []
            },
            parcels: [
                { name : 'preload' }
            ]
        }
    }

    /**
     * Create a new flurry project in the directory this command is invoked from.
     */
    @:defaultCommand public function create()
    {
        fs.directory.create(resources);
        fs.directory.create(codepath);

        fs.file.writeText(Path.join([ codepath, '$main.hx' ]), getCode(name));
        fs.file.writeText(Path.join([ resources, 'assets.json' ]), Json.stringify(assets));
        fs.file.writeText('build.json', Json.stringify(getProject(name, main, codepath, output, resources, author)));
    }

    /**
     * Prints out help about the create command.
     */
    @:command public function help()
    {
        Console.println(Cli.getDoc(this));
    }

    /**
     * Create a project typedef for json serialisation.
     */
    static function getProject(_name, _main, _codepath, _output, _assets, _author) : Project
    {
        return {
            app : {
                name      : _name,
                backend   : Sdl,
                codepaths : [ _codepath ],
                main      : _main,
                output    : _output,
                author    : _author
            },
            build : {
                dependencies : [
                    { lib : 'flurry' }
                ]
            },
            parcels: [ '$_assets/assets.json' ]
        }
    }

    /**
     * Get the initial code for the main class.
     */
    static function getCode(_name)
    {
        return 'package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;

class Main extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = \'$_name\';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = [ \'preload\' ];

        return _config;
    }
}';
    }
}