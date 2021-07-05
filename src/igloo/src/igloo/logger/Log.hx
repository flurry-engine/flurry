package igloo.logger;

import haxe.Exception;
import haxe.MainLoop;

class Log
{
    public function info(_message : String)
    {
        //
    }

    public function success(_message : String)
    {
        //
    }

    public function error(_message : String, _exception : Exception)
    {
        //
    }

    public function debug(_message : String)
    {
        //
    }
}

class ScriptLogger extends Log
{
    final scriptName : String;

    public function new(_scriptName)
    {
        scriptName = _scriptName;
    }

    override function error(_message : String, _exception : Exception)
    {
        MainLoop.runInMainThread(() -> {
            Console.printlnFormatted('<#ea8220>[Processor]</><red>[ERR]</>[$scriptName] $_message\n${ _exception.details() }', Error);
        });
    }

    override function info(_message : String)
    {
        MainLoop.runInMainThread(() -> {
            Console.printlnFormatted('<#ea8220>[Processor]</>[INF][$scriptName] $_message');
        });
    }

    override function success(_message : String)
    {
        MainLoop.runInMainThread(() -> {
            Console.printlnFormatted('<#ea8220>[Processor]</><green>[SUC]</>[$scriptName] $_message');
        });
    }

    override function debug(_message : String)
    {
        MainLoop.runInMainThread(() -> {
            Console.printlnFormatted('<#ea8220>[Processor]</>[DBG][$scriptName] $_message', Debug);
        });
    }
}