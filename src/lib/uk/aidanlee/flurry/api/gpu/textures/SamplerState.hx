package uk.aidanlee.flurry.api.gpu.textures;

abstract SamplerState(Int)
{
    public static final nearest = new SamplerState(Clamp, Clamp, Nearest, Nearest);

    public static final linear = new SamplerState(Clamp, Clamp, Linear, Linear);

    public var uClamping (get, never) : EdgeClamping;

    inline function get_uClamping() return cast this & 0x7;

    public var vClamping (get, never) : EdgeClamping;

    inline function get_vClamping() return cast this >>> 3 & 0x7;

    public var minification (get, never) : Filtering;

    inline function get_minification() return cast this >>> 6 & 0x1;

    public var magnification (get, never) : Filtering;

    inline function get_magnification() return cast this >>> 7 & 0x1;

    public function new(
        _uClamping     : EdgeClamping,
        _vClamping     : EdgeClamping,
        _minification  : Filtering,
        _magnification : Filtering)
    {
        this = (_uClamping & 0x7) | ((_vClamping & 0x7) << 3) | ((_minification & 0x1) << 6) | ((_magnification & 0x1) << 7);
    }
}