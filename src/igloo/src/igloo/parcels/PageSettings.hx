package igloo.parcels;

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