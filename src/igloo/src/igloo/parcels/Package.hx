package igloo.parcels;

class Package
{
    public var assets : Array<Asset>;

    public var parcels : Array<Parcel>;

    public function new()
    {
        assets  = [];
        parcels = [];
    }
}