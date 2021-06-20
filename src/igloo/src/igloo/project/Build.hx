package igloo.project;

class Build
{
    @:optional
    public var dependencies : Array<String>;

    @:optional
    public var defines : Array<Define>;

    @:optional
    public var macros : Array<String>;

    @:optional
    public var files : Map<String, String>;

    @:optional
    public var processors : Array<Processor>;

    public function new()
    {
        dependencies  = [];
        defines       = [];
        macros        = [];
        files         = [];
        processors    = [];
    }
}