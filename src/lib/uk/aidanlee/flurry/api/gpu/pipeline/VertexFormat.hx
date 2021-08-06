package uk.aidanlee.flurry.api.gpu.pipeline;

abstract VertexFormat(Int) to Int
{
    public var count (get, never) : Int;

    inline function get_count() return this & 0xF;

    public function new(
        _count : Int,
        _el1 : VertexElement,
        _el2 : VertexElement,
        _el3 : VertexElement,
        _el4 : VertexElement,
        _el5 : VertexElement)
    {
        this =
            (_count & 0xF) |
            ((_el1 & 0x1F) << 4) |
            ((_el2 & 0x1F) << 9) |
            ((_el3 & 0x1F) << 14) |
            ((_el4 & 0x1F) << 19) |
            ((_el5 & 0x1F) << 24);
    }

    public function get(_idx : Int)
    {
        final shift = 4 + (_idx * 5);
        final value = this >>> shift & 0x1F;

        return (cast value : VertexElement);
    }
}
