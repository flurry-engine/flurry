package igloo.project;

class Define
{
    public var def : String;

    @:optional
    public var value : String;

    public function new()
    {
        def   = '';
        value = '';
    }
}