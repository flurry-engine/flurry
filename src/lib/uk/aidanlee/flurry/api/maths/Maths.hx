package uk.aidanlee.flurry.api.maths;

import VectorMath;

function boolToInt(_b)
{
    return if (_b) 1 else 0;
}

function intToBool(_i)
{
    return if (_i == 0) false else true;
}

function polarToCartesian(_length : Float, _direction : Float)
{
    return vec2(
         Math.cos(radians(_direction)) * _length,
        -Math.sin(radians(_direction)) * _length
    );
}

function distanceBetween(_p1 : Vec2, _p2 : Vec2)
{
    return Math.sqrt(Math.pow(_p2.x - _p1.x, 2) + Math.pow(_p2.y - _p1.y, 2));
}

function angleBetween(_p1 : Vec2, _p2 : Vec2)
{
    return degrees(Math.atan2(_p1.y - _p2.y, _p2.x - _p1.x));
}

function nextMultipleOff(_number : Float, _multiple : Int)
{
    return Math.ceil(_number / _multiple) * _multiple;
}

/**
 * Fixes a float to a specific number of decimal places.
 * @param _v Flaot.
 * @param _p Precision.
 * @return Float
 */
function fixed(_v : Float, _p : Int)
{
   final n = Math.pow(10, _p);

   return Std.int(_v * n) / n;
}

/**
 * Keeps a float within a specified range.
 * @param _value The float to clamp.
 * @param _a     Lower limit of the range.
 * @param _b     Upper limit of the range.
 * @return Float
 */
function clamp(_value : Float, _a : Float, _b : Float)
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
function lerp(_value : Float, _target : Float, _time : Float)
{
   final clamped = clamp(_time, 0, 1);

   return (_value + clamped * (_target - _value));
}