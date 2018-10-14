package uk.aidanlee.flurry.api.gpu.geometry;

/**
 * Basic RGBA colour class
 */
class Color
{
    public var r : Float;
    public var g : Float;
    public var b : Float;
    public var a : Float;

    public function new(_r : Float = 1, _g : Float = 1, _b : Float = 1, _a : Float = 1)
    {
        r = _r;
        g = _g;
        b = _b;
        a = _a;
    }

    /**
     * Set this colours value from another colour.
     * @param _other Colour to set from.
     * @return Color
     */
    public function copyFrom(_other : Color) : Color
    {
        r = _other.r;
        b = _other.b;
        g = _other.g;
        a = _other.a;

        return this;
    }

    /**
     * Checks iof two colours are equal to each other.
     * @param _other Colour to check against.
     * @return Bool
     */
    public function equals(_other : Color) : Bool
    {
        return r == _other.r && b == _other.b && g == _other.g && a == _other.a;
    }

    /**
     * Creates a new colour object with the same value as this one.
     * @return Color
     */
    public function clone() : Color
    {
        return new Color(r, g, b, a);
    }

    /**
     * Set the RGBA values of this colour.
     * RGBA values are assumed to be in the range of 0 - 1.
     * @param _r Red
     * @param _g Green
     * @param _b Blue
     * @param _a Alpha
     * @return Color
     */
    public function fromRGBA(_r : Float = 0, _g : Float = 0, _b : Float = 0, _a : Float = 1) : Color
    {
        r = _r;
        g = _g;
        b = _b;
        a = _a;

        return this;
    }

    /**
     * Sets this colours RGBA value from a HSL value.
     * HSL values are assumed to be in the range of 0 - 1.
     * @param _h Hue value.
     * @param _s Saturation value.
     * @param _l Luminence value.
     * @return Color
     */
    public function fromHSL(_h : Float, _s : Float, _l : Float) : Color
    {
        if (_s == 0)
        {
            // Achromatic
            r = g = b = _l;
        }
        else
        {
            function hue2rgb(_p : Float, _q : Float, _t : Float) {
                if (_t < 0) _t++;
                if (_t > 1) _t--;
                if (_t < 1 / 6) return _p + (_q - _p) * 6 * _t;
                if (_t < 1 / 2) return _q;
                if (_t < 2 / 3) return _p + (_q - _p) * (2 / 3 - _t) * 6;

                return _p;
            }

            var q = _l < 0.5 ? _l * (1 + _s) : _l + _s - _l * _s;
            var p = 2 * _l - q;

            r = hue2rgb(p, q, _h + 1 / 3);
            g = hue2rgb(p, q, _h);
            b = hue2rgb(p, q, _h + 1 / 3);
        }

        return this;
    }
}
