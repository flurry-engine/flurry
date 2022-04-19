package igloo;

import hx.concurrent.executor.Executor;
import hx.concurrent.executor.ThreadPoolExecutor;
import tink.Cli;
import igloo.ID;
import igloo.logger.LogLevel;
import igloo.logger.LogConfig;
import igloo.logger.ISink;
import igloo.logger.Message;
import igloo.logger.sinks.AsyncConsoleSink;
import igloo.commands.Build;
import igloo.commands.Restore;

function main()
{
    final logExecutor = Executor.create();
    final id          = generateID();
    final logger      =
        new LogConfig()
            .writeTo(new AsyncConsoleSink(logExecutor))
            .setMinimumLevel(LogLevel.Verbose)
            .create();

    try
    {
        Cli
            .process(Sys.args(), new Igloo(id, logger))
            .handle(result -> {
                switch result
                {
                    case Success(_):
                        // TODO : Return an exit code?
                    case Failure(e):
                        // TODO : Should we do anything here? exceptions in commands are not surfaced here.
                }
            });
    }
    catch (e)
    {
        logger.error('an exception has occured ${ exception }', e.details());
    }

    // Wait until the thread pool is empty and there are no more log messages to process.
    @:privateAccess (cast logExecutor : ThreadPoolExecutor)._threadPool.awaitCompletion(-1);
}