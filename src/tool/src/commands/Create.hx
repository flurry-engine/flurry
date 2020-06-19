package commands;

import Types.Unit;
import Types.Result;
import Types.Project;
import parcel.Types.JsonDefinition;
import tink.Json;
import haxe.io.Path;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;

using Safety;

class Create
{
    final fs : IFileSystem;

    final project : Project;

    final assets : JsonDefinition;

    final main : String;

    public function new(_fs : IFileSystem = null)
    {
        fs      = _fs.or(new FileSystem());
        project = {
            app : {
                name      : 'Project',
                backend   : Snow,
                codepaths : [ 'src' ],
                main      : 'Main',
                output    : 'bin',
                namespace : 'com.organisation.Project'
            },
            build : {
                dependencies : [
                    { lib : 'flurry' }
                ]
            },
            parcels: [ 'assets/assets.json' ]
        }
        assets = {
            assets : {
                bytes   : [],
                shaders : [],
                sheets  : [],
                images  : [],
                fonts   : [],
                texts   : []
            },
            parcels: [
                { name : 'preload', depends : [] }
            ]
        }
        main = 'package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;

class Main extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = \'Project\';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = \'preload\';

        return _config;
    }
}';
    }

    public function run() : Result<Unit>
    {
        fs.directory.create('assets');
        fs.directory.create('src');

        fs.file.writeText(Path.join([ 'src', 'Main.hx' ]), main);
        fs.file.writeText(Path.join([ 'assets', 'assets.json' ]), Json.stringify(assets));
        fs.file.writeText('build.json', Json.stringify(project));

        return Success(Unit.value);
    }
}