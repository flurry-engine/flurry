package igloo;

import haxe.MainLoop;
import tink.Cli;
import igloo.commands.Build;

function main()
{
    MainLoop.addThread(start);
}

function start()
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