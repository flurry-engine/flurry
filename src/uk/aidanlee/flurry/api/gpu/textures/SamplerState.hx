package uk.aidanlee.flurry.api.gpu.textures;

using haxe.EnumTools;

class SamplerState
{
    public var uClamping : EdgeClamping;

    public var vClamping : EdgeClamping;

    public var minification : Filtering;

    public var magnification : Filtering;

    public function new(
        _uClamping     : EdgeClamping,
        _vClamping     : EdgeClamping,
        _minification  : Filtering,
        _magnification : Filtering)
    {
        uClamping     = _uClamping;
        vClamping     = _vClamping;
        minification  = _minification;
        magnification = _magnification;
    }

    public function equal(_other : SamplerState)
    {
        return
            uClamping == _other.uClamping &&
            vClamping == _other.vClamping &&
            minification == _other.minification &&
            magnification == _other.magnification;
    }

    public function hash() : Int
    {
        var hash = 23;
        hash *= 31 + uClamping.getIndex();
        hash *= 31 + vClamping.getIndex();
        hash *= 31 + minification.getIndex();
        hash *= 31 + magnification.getIndex();

        return hash;
    }
}