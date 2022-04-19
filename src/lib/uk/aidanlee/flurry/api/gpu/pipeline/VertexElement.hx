package uk.aidanlee.flurry.api.gpu.pipeline;

abstract VertexElement(Int) to Int
{
    public static final none = new VertexElement(0, Vector2);

    public var location (get, never) : Int;

    inline function get_location() return this >>> 2 & 0x7;

    public var type (get, never) : VertexType;

    inline function get_type() return cast this & 0x3;

    public function new(_location : Int, _type : VertexType)
    {
        this =
            (_type & 0x3) |
            ((_location & 0x7) << 2);
    }
}

enum abstract VertexType(Int) to Int
{
    var Vector2;
    var Vector3;
    var Vector4;
}