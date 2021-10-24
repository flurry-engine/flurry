package igloo;

import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.executor.Executor;
import tink.Cli;
import igloo.ID;
import igloo.logger.LogLevel;
import igloo.logger.LogConfig;
import igloo.logger.ISink;
import igloo.logger.Message;
import igloo.commands.Build;

function main()
{
    final logExecutor   = Executor.create();
    final id            = generateID();
    final logger =
        new LogConfig()
            .writeTo(new AsyncConsoleSink(logExecutor))
            .setMinimumLevel(LogLevel.Verbose)
            .create();

    try
    {
        Cli.process(Sys.args(), new Igloo(id, logger)).handle(Cli.exit);
    }
    catch (e)
    {
        logger.error('Igloo failed to build the project $e');
    }
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
        switch _message.level
        {
            case Verbose, Information:
                Console.log(_message);
            case Debug:
                Console.debug(_message);
            case Warning:
                Console.warn(_message);
            case Error:
                Console.error(_message);
        }
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