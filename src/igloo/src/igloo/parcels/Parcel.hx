package igloo.parcels;

class Parcel
{
    public var name : String;

    public var assets : Array<String>;

    @:optional
    @:default(new igloo.parcels.PageSettings())
    public var settings : PageSettings;

    public function new(_name, _assets)
    {
        name     = '';
        assets   = [];
        settings = new PageSettings();
    }
}