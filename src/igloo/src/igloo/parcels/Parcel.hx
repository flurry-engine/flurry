package igloo.parcels;

class Parcel
{
    public var name : String;

    public var assets : Array<String>;

    public function new(_name, _assets)
    {
        name   = '';
        assets = [];
    }
}