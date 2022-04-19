package igloo.parcels;

class Parcel
{
    public var name : String;

    public var assets : Array<Asset>;

    @:optional
    @:default(new igloo.parcels.Parcel.PageSettings())
    public var settings : PageSettings;

    public function new(_name, _assets)
    {
        name     = '';
        assets   = [];
        settings = new PageSettings();
    }
}

class Asset
{
    public var id : String;

    public var path : String;

    public function new()
    {
        id   = '';
        path = '';
    }
}

class PageSettings
{
    public var maxWidth : Int;
    public var maxHeight : Int;
    public var xPad : Int;
    public var yPad : Int;
    public var format : String;

    public function new()
    {
        maxWidth  = 4096;
        maxHeight = 4096;
        xPad      = 2;
        yPad      = 2;
        format    = 'png';
    }
}