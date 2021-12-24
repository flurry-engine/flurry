package igloo;

import tink.Cli;
import igloo.commands.Build;
import igloo.commands.Restore;

@:alias(false)
class Igloo
{
    /**
     * Build the projects parcels and code.
     */
    @:command
    public final build : Build;

    /**
     * Download all external dependencies for the project.
     */
    @:command
    public final restore : Restore;

    public function new(_id, _logger)
    {
        build   = new Build(_id, _logger);
        restore = new Restore(_logger);
    }

    @:defaultCommand
    public function help()
    {
        Sys.println(Cli.getDoc(this));
    }
}