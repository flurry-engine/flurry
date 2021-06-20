package igloo.project;

class App
{
    public var backend : Backend;

    public var codepaths : Array<String>;

    public var main : String;

    public var name : String;

    public var author : String;

    public var output : String;

    public function new()
    {
        backend   = Sdl;
        codepaths = [];
        main      = '';
        name      = '';
        author    = '';
        output    = 'bin';
    }
}