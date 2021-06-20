package igloo.project;

class Processor
{
    public var source : String;

    @:optional
    @:default('')
    public var flags : String;

    public function new()
    {
        source = '';
        flags  = '';
    }
}