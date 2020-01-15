package uk.aidanlee.flurry.api.gpu.textures;

class SamplerState
{
    public final uClamping : EdgeClamping;

    public final vClamping : EdgeClamping;

    public final minification : Filtering;

    public final magnification : Filtering;

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
        hash *= 31 + (cast uClamping : Int);
        hash *= 31 + (cast vClamping : Int);
        hash *= 31 + (cast minification : Int);
        hash *= 31 + (cast magnification : Int);

        return hash;
    }
}