package uk.aidanlee.flurry.api.gpu.state;

class BlendState
{
    /**
     * If blending is enabled for this state.
     */
    public var enabled : Bool;

    /**
     * The source colour for blending.
     */
    public var srcRGB : BlendMode;

    /**
     * The source alpha for blending.
     */
    public var srcAlpha : BlendMode;

    /**
     * The destination color for blending.
     */
    public var dstRGB : BlendMode;

    /**
     * The destination alpha for blending.
     */
    public var dstAlpha : BlendMode;

    public function new(
        _enabled  : Bool = true,
        _srcRGB   : BlendMode = SrcAlpha,
        _srcAlpha : BlendMode = One,
        _dstRGB   : BlendMode = OneMinusSrcAlpha,
        _dstAlpha : BlendMode = Zero
    )
    {
        enabled  = _enabled;
        srcRGB   = _srcRGB;
        srcAlpha = _srcAlpha;
        dstRGB   = _dstRGB;
        dstAlpha = _dstAlpha;
    }

    public function equals(_other : BlendState) : Bool
    {
        return enabled  == _other.enabled  &&
               srcRGB   == _other.srcRGB   &&
               srcAlpha == _other.srcAlpha &&
               dstRGB   == _other.dstRGB   &&
               dstAlpha == _other.dstAlpha;
    }

    public function copyFrom(_other : BlendState) : BlendState
    {
        enabled  = _other.enabled;
        srcRGB   = _other.srcRGB;
        srcAlpha = _other.srcAlpha;
        dstRGB   = _other.dstRGB;
        dstAlpha = _other.dstAlpha;

        return this;
    }

    public function clone() : BlendState
    {
        return new BlendState(enabled, srcRGB, srcAlpha, dstRGB, dstAlpha);
    }
}
