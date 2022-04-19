package igloo.logger;

class LogConfig
{
    final sinks : Array<ISink>;
    final extra : Array<Enrichment>;
    var level : LogLevel;

    public function new()
    {
        sinks = [];
        extra = [];
        level = Information;
    }

    public function writeTo(_sink : ISink)
    {
        sinks.push(_sink);

        return this;
    }

    public function enrichWith(_field : String, _value : Any)
    {
        extra.push({ field : _field, value : _value });

        return this;
    }

    public function setMinimumLevel(_level : LogLevel)
    {
        level = _level;

        return this;
    }

    public function create()
    {
        return new Log(extra, sinks, level);
    }
}