package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.maths.Maths;

abstract StencilState(Int)
{
    public static final none = new StencilState(false, Always, Keep, Keep, Keep, Always, Keep, Keep, Keep);

    public var enabled (get, never) : Bool;

    inline function get_enabled() return Maths.intToBool(this & 0x1);

    public var frontFunc (get, never) : ComparisonFunction;

    inline function get_frontFunc() return cast this >>> 1 & 0x7;

    public var frontTestFail (get, never) : StencilFunction;

    inline function get_frontTestFail() return cast this >>> 4 & 0x7;

    public var frontDepthTestFail (get, never) : StencilFunction;

    inline function get_frontDepthTestFail() return cast this >>> 7 & 0x7;

    public var frontDepthTestPass (get, never) : StencilFunction;

    inline function get_frontDepthTestPass() return cast this >>> 10 & 0x7;

    public var backFunc (get, never) : ComparisonFunction;

    inline function get_backFunc() return cast this >>> 13 & 0x7;

    public var backTestFail (get, never) : StencilFunction;

    inline function get_backTestFail() return cast this >>> 16 & 0x7;

    public var backDepthTestFail (get, never) : StencilFunction;

    inline function get_backDepthTestFail() return cast this >>> 19 & 0x7;

    public var backDepthTestPass (get, never) : StencilFunction;

    inline function get_backDepthTestPass() return cast this >>> 22 & 0x7;

    public function new(
        _enabled : Bool,
        _frontFunc : ComparisonFunction,
        _frontTestFail : StencilFunction,
        _frontDepthTestFail : StencilFunction,
        _frontDepthTestPass : StencilFunction,
        _backFunc : ComparisonFunction,
        _backTestFail : StencilFunction,
        _backDepthTestFail : StencilFunction,
        _backDepthTestPass : StencilFunction
    )
    {
        this =
            (Maths.boolToInt(_enabled) & 0x1) |
            ((_frontFunc & 0x7) << 1) |
            ((_frontTestFail & 0x7) << 4) |
            ((_frontDepthTestFail & 0x7) << 7) |
            ((_frontDepthTestPass & 0x7) << 10) |
            ((_backFunc & 0x7) << 13) |
            ((_backTestFail & 0x7) << 16) |
            ((_backDepthTestFail & 0x7) << 19) |
            ((_backDepthTestPass & 0x7) << 22);
    }
}