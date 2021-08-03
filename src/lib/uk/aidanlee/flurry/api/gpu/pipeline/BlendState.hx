package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.maths.Maths;

abstract BlendState(Int)
{
    public static final none = new BlendState(true, SrcAlpha, One, OneMinusSrcAlpha, Zero);

    public var enabled (get, never) : Bool;

    inline function get_enabled() return this & 0x1 == 1;

    public var srcRgb (get, never) : BlendMode;

    inline function get_srcRgb() return cast this >>> 1 & 0xF;

    public var srcAlpha (get, never) : BlendMode;

    inline function get_srcAlpha() return cast this >>> 5 & 0xF;

    public var dstRgb (get, never) : BlendMode;

    inline function get_dstRgb() return cast this >>> 9 & 0xF;

    public var dstAlpha (get, never) : BlendMode;

    inline function get_dstAlpha() return cast this >>> 13 & 0xF;

    public function new(
        _enabled : Bool,
        _srcRgb : BlendMode,
        _srcAlpha : BlendMode,
        _dstRgb : BlendMode,
        _dstAlpha : BlendMode)
    {
        this = (((((((_dstAlpha << 4) | (_dstRgb & 0xF)) << 4) | (_srcAlpha & 0xF)) << 4) | (_srcRgb & 0xF)) << 1) | (Maths.boolToInt(_enabled) & 0x1);
    }
}