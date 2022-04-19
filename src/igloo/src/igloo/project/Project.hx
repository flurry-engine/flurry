package igloo.project;

class Project
{
    public var app : App;

    public var build : Build;

    public var parcels : Array<String>;

    public function new()
    {
        app     = new App();
        build   = new Build();
        parcels = [];
    }
}