package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.maths.Maths;

abstract BlendState(Int)
{
    public static final none = new BlendState(true, One, OneMinusSrcAlpha, Add);

    public var enabled (get, never) : Bool;

    inline function get_enabled() return this & 0x1 == 1;

    public var srcFactor (get, never) : BlendMode;

    inline function get_srcFactor() return cast this >>> 1 & 0xF;

    public var dstFactor (get, never) : BlendMode;

    inline function get_dstFactor() return cast this >>> 5 & 0xF;

    public var op (get, never) : BlendOp;

    inline function get_op() return cast this >>> 9 & 0x7;

    public function new(
        _enabled : Bool,
        _srcFactor : BlendMode,
        _dstFactor : BlendMode,
        _op : BlendOp)
    {
        this =
            (boolToInt(_enabled) & 0x1) |
            ((_srcFactor & 0xF) << 1) |
            ((_dstFactor & 0xF) << 5) |
            ((_op & 0x7) << 9);
    }
}