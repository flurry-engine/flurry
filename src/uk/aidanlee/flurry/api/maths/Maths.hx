package uk.aidanlee.flurry.api.maths;

/**
 * Provides various util functions for maths related stuff.
 * Also provides inline wrappers to Haxe's std maths for consistent Maths access.
 */
class Maths
{
    /**
     * Fixes a float to a specific number of decimal places.
     * @param _v Flaot.
     * @param _p Precision.
     * @return Float
     */
    public static inline function fixed(_v : Float, _p : Int) : Float
    {
        var n = Maths.pow(10, _p);
        return Std.int(_v * n) / n;
    }

    /**
     * Keeps a float within a specified range.
     * @param _value The float to clamp.
     * @param _a     Lower limit of the range.
     * @param _b     Upper limit of the range.
     * @return Float
     */
    public static inline function clamp(_value : Float, _a : Float, _b : Float) : Float
    {
        return (_value < _a) ? _a : ((_value > _b) ? _b : _value);
    }

    /**
     * Linearly iterpolate a float towards a target.
     * @param _value  Starting value.
     * @param _target Value to interpolate towards.
     * @param _time   Interpolation time.
     * @return Float
     */
    public static inline function lerp(_value : Float, _target : Float, _time : Float) : Float
    {
        _time = clamp(_time, 0, 1);

        return (_value + _time * (_target - _value));
    }

    /**
     * Converts degrees into radians.
     * @param _degrees Degrees value to radians.
     * @return Float
     */
    public static inline function toRadians(_degrees : Float) : Float
    {
        return _degrees * PI / 180;
    }

    /**
     * Convert radians into degrees.
     * @param _radians Radians value to convert.
     * @return Float
     */
    public static inline function toDegrees(_radians : Float) : Float
    {
        return _radians * 180 / PI;
    }

    public static inline function lengthdir_x(_length : Float, _direction : Float) : Float
    {
        return Maths.cos(Maths.toRadians(_direction)) * _length;
    }

    public static inline function lengthdir_y(_length : Float, _direction : Float) : Float
    {
        return Maths.sin(Maths.toRadians(_direction)) * _length;
    }

    public static inline function nextMultipleOff(_number : Float, _multiple : Int) : Int
    {
        return Maths.ceil(_number / _multiple) * _multiple;
    }

    // Wrapper functions around std Math for consistent access. 

    public static final NEGATIVE_INFINITY = Math.NEGATIVE_INFINITY;

    public static final POSITIVE_INFINITY = Math.POSITIVE_INFINITY;

    public static final NaN = Math.NaN;

    public static final PI = Math.PI;

    public static inline function abs(_v : Float) : Float return Math.abs(_v);

    public static inline function acos(_v : Float) : Float return Math.acos(_v);

    public static inline function asin(_v : Float) : Float return Math.asin(_v);

    public static inline function atan(_v : Float) : Float return Math.atan(_v);

    public static inline function atan2(_y : Float, _x : Float) : Float return Math.atan2(_y, _x);

    public static inline function ceil(_v : Float) : Int return Math.ceil(_v);

    public static inline function floor(_v : Float) : Int return Math.floor(_v);

    public static inline function cos(_v : Float) : Float return Math.cos(_v);

    public static inline function sin(_v : Float) : Float return Math.sin(_v);

    public static inline function tan(_v : Float) : Float return Math.tan(_v);

    public static inline function exp(_v : Float) : Float return Math.exp(_v);

    public static inline function fceil(_v : Float) : Float return Math.fceil(_v);

    public static inline function ffloor(_v : Float) : Float return Math.ffloor(_v);

    public static inline function round(_v : Float) : Int return Math.round(_v);

    public static inline function fround(_v : Float) : Float return Math.fround(_v);

    public static inline function isFinite(_v : Float) : Bool return Math.isFinite(_v);

    public static inline function isNaN(_v : Float) : Bool return Math.isNaN(_v);

    public static inline function log(_v : Float) : Float return Math.log(_v);

    public static inline function max(_a : Float, _b : Float) : Float return Math.max(_a, _b);

    public static inline function min(_a : Float, _b : Float) : Float return Math.min(_a, _b);

    public static inline function pow(_v : Float, _exp : Float) : Float return Math.pow(_v, _exp);

    public static inline function random() : Float return Math.random();

    public static inline function sqrt(_v : Float) : Float return Math.sqrt(_v);
}
