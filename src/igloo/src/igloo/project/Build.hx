package igloo.project;

class Build
{
    @:optional
    @:default(new Array<String>())
    public var dependencies : Array<String>;

    @:optional
    @:default(new Array<igloo.project.Define>())
    public var defines : Array<Define>;

    @:optional
    @:default(new Array<String>())
    public var macros : Array<String>;

    @:optional
    @:default(new Map<String, String>())
    public var files : Map<String, String>;

    @:optional
    @:default(new Array<igloo.project.Processor>())
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