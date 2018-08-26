package uk.aidanlee.gpu;

class Texture
{
    public final textureID : Int;

    public var width : Int;
    
    public var height : Int;

    public function new(_id : Int, _width : Int, _height : Int)
    {
        textureID = _id;
        width     = _width;
        height    = _height;
    }
}
