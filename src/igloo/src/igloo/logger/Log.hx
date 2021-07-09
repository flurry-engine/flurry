package igloo.logger;

import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.executor.ThreadPoolExecutor;
import haxe.Exception;

class Log
{
    final dispatcher : AsyncEventDispatcher<String>;

    public function new(_dispatcher)
    {
        dispatcher = _dispatcher;
        dispatcher.subscribe(log);
    }

    public function info(_message : String)
    {
        dispatcher.fire(_message);
    }

    public function success(_message : String)
    {
        dispatcher.fire(_message);
    }

    public function error(_message : String, _exception : Exception)
    {
        dispatcher.fire('$_message\n${ _exception.details() }');
    }

    public function debug(_message : String)
    {
        dispatcher.fire(_message);
    }

    public function flush()
    {
        @:privateAccess (cast dispatcher._executor : ThreadPoolExecutor)._threadPool.awaitCompletion(-1);
        @:privateAccess (cast dispatcher._executor : ThreadPoolExecutor).stop();
    }

    function log(_message)
    {
        Console.printlnFormatted(_message);
    }
}

class ScriptLogger
{
    final log : Log;

    final scriptName : String;

    public function new(_log, _scriptName)
    {
        log        = _log;
        scriptName = _scriptName;
    }

    public function error(_message : String, _exception : Exception)
    {
        log.error('<#ea8220>[Processor]</><red>[ERR]</>[$scriptName] $_message', _exception);
    }

    public function info(_message : String)
    {
        log.info('<#ea8220>[Processor]</>[INF][$scriptName] $_message');
    }

    public function success(_message : String)
    {
        log.success('<#ea8220>[Processor]</><green>[SUC]</>[$scriptName] $_message');
    }

    public function debug(_message : String)
    {
        log.debug('<#ea8220>[Processor]</>[DBG][$scriptName] $_message');
    }
}