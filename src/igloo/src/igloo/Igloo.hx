package igloo;

import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.executor.Executor;
import tink.Cli;
import igloo.ID;
import igloo.logger.Log;
import igloo.commands.Build;

function main()
{
    final logExecutor   = Executor.create();
    final logDispatcher = new AsyncEventDispatcher<String>(logExecutor);
    final logger        = new Log(logDispatcher);
    final id            = generateID();

    try
    {
        Cli.process(Sys.args(), new Igloo(id, logger)).handle(Cli.exit);
    }
    catch (e)
    {
        logger.error('Igloo failed to build the project', e);
    }

    logger.flush();
}

@:alias(false)
class Igloo
{
    /**
     * Build the projects parcels and code.
     */
    @:command
    public final build : Build;

    public function new(_id, _logger)
    {
        build = new Build(_id, _logger);
    }

    @:defaultCommand
    public function help()
    {
        Sys.println(Cli.getDoc(this));
    }
}