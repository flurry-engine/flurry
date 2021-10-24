package igloo.logger;

interface ISink
{
    function getLevel() : LogLevel;
    function onMessage(_message : Message) : Void;
}