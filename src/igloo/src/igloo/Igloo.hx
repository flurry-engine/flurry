package igloo;

import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.executor.Executor;
import tink.Cli;
import igloo.logger.Log;
import igloo.commands.Build;

function main()
{
    final logExecutor   = Executor.create();
    final logDispatcher = new AsyncEventDispatcher<String>(logExecutor);
    final logger        = new Log(logDispatcher);

    try
    {
        Cli.process(Sys.args(), new Igloo(logger)).handle(Cli.exit);
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
    @:command
    public final build : Build;

    public function new(_logger)
    {
        build = new Build(_logger);
    }

    @:defaultCommand
    public function help()
    {
        Sys.println('help');
    }
}