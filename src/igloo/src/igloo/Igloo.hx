package igloo;

import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.executor.Executor;
import hx.concurrent.executor.ThreadPoolExecutor;
import tink.Cli;
import igloo.ID;
import igloo.logger.LogLevel;
import igloo.logger.LogConfig;
import igloo.logger.ISink;
import igloo.logger.Message;
import igloo.commands.Build;
import igloo.commands.Restore;

function main()
{
    final logExecutor = Executor.create();
    final id          = generateID();
    final logger      = new LogConfig()
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

class AsyncConsoleSink implements ISink
{
    final dispatcher : AsyncEventDispatcher<Message>;

    public function new(_executor)
    {
        dispatcher = new AsyncEventDispatcher<Message>(_executor);
        dispatcher.subscribe(printMessage);
    }

    public function getLevel()
    {
        return LogLevel.Verbose;
    }

    public function onMessage(_message : Message)
    {
        dispatcher.fire(_message);
    }

    function printMessage(_message : Message)
    {
        Sys.println(_message.toString());
    }
}

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