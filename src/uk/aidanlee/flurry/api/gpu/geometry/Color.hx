package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.maths.Vector4;

/**
 * Basic RGBA colour class
 */
@:forward(offset, changed)
abstract Color(Vector4) from Vector4 to Vector4 from Float32BufferData to Float32BufferData
{
    public var r (get, set) : Float;

    inline function get_r() : Float return this.x;

    inline function set_r(_v) : Float return this.x = _v;

    public var g (get, set) : Float;

    inline function get_g() : Float return this.y;

    inline function set_g(_v) : Float return this.y = _v;

    public var b (get, set) : Float;

    inline function get_b() : Float return this.z;

    inline function set_b(_v) : Float return this.z = _v;

    public var a (get, set) : Float;

    inline function get_a() : Float return this.w;

    inline function set_a(_v) : Float return this.w = _v;

    public function new(_r : Float = 1, _g : Float = 1, _b : Float = 1, _a : Float = 1)
    {
        this = new Vector4(_r, _g, _b, _a);
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

        return cast this;
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

        return cast this;
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
            function hue2rgb(_p : Float, _q : Float, _t : Float) : Float {
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

        return cast this;
    }
}
