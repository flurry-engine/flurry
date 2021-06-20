package igloo;

import tink.Cli;
import igloo.commands.Build;

function main()
{
    Cli.process(Sys.args(), new Igloo()).handle(Cli.exit);
}

@:alias(false)
class Igloo
{
    @:command
    public final build : Build;

    public function new()
    {
        build = new Build();
    }

    @:defaultCommand
    public function help()
    {
        Sys.println('help');
    }
}