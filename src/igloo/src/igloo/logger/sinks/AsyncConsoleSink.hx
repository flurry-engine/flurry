package igloo.logger.sinks;

import hx.concurrent.event.AsyncEventDispatcher;

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