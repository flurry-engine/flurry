package;

import tink.Cli;

class Main
{
    public static function main()
    {
        Cli.process(Sys.args(), new Main()).handle(Cli.exit);
    }

    public function new()
    {
        json         = '';
        directory    = '';
        compress     = true;
        ignoreHidden = true;
        verbose      = false;
        output       = 'output.parcel';
    }

    @:flag('-from-json')
    public var json : String;

    @:flag('-from-directory')
    public var directory : String;

    @:flag('-output')
    public var output : String;

    @:flag('--compress')
    public var compress : Bool;

    @:flag('--ignore-hidden')
    public var ignoreHidden : Bool;

    @:flag('--verbose')
    public var verbose : Bool;

    @:defaultCommand
    public function help()
    {
        trace('help');
    }

    @:command
    public function create()
    {
        if (json != '')
        {
            Parcel.createFromJson(json, output, compress, verbose);
        }

        if (directory != '')
        {
            Parcel.createFromDirectory(directory, output, compress, ignoreHidden, verbose);
        }
    }

    @:command
    public function unpack()
    {
        Parcel.unpack(directory);
    }
}
