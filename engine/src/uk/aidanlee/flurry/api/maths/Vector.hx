package uk.aidanlee.flurry.api.maths;

import snow.api.buffers.Float32Array;

/**
 * Vector class which contains an x, y, z, and w component.
 */
class Vector
{
    /**
     * x component of this vector.
     */
    public var x : Float;

    /**
     * y component of this vector.
     */
    public var y : Float;

    /**
     * z component of this vector.
     */
    public var z : Float;

    /**
     * w component of this vector.
     */
    public var w : Float;

    /**
     * The length of this vector.
     */
    public var length (get, never) : Float;

    inline function get_length() : Float {
        return Maths.sqrt(x * x + y * y + z * z);
    }

    /**
     * The square of this vectors length.
     */
    public var lengthsq (get, never) : Float;

    inline function get_lengthsq() : Float {
        return x * x + y * y + z + z;
    }

    /**
     * The 2D angle this vector represents.
     */
    public var angle2D (get, never) : Float;

    inline function get_angle2D() : Float {
        return Maths.atan2(y, x);
    }

    /**
     * Normalized version of this vector.
     */
    public var normalized (get, never) : Vector;

    inline function get_normalized() : Vector {
        var len = length;
        return new Vector(x / len, y / len, z / len);
    }

    /**
     * Inverted version of this vector.
     */
    public var inverted (get, never) : Vector;

    inline function get_inverted() : Vector {
        return new Vector(-x, -y, -z);
    }

    /**
     * Create a new vector instance.
     * @param _x x value of the vector.
     * @param _y y value of the vector.
     * @param _z z value of the vector.
     * @param _w w value of the vector.
     */
    public function new(_x : Float = 0, _y : Float = 0, _z : Float = 0, _w : Float = 0)
    {
        this = new Float32Array(4);

        x = _x;
        y = _y;
        z = _z;
        w = _w;
    }

    // #region overloaded operators

    @:op(A + B) inline public function opAdd(_rhs : Vector) : Vector
    {
        return add(_rhs);
    }

    @:op(A - B) inline public function opSubtract(_rhs : Vector) : Vector
    {
        return subtract(_rhs);
    }

    @:op(A * B) inline public function opMultiply(_rhs : Vector) : Vector
    {
        return multiply(_rhs);
    }

    @:op(A / B) inline public function opDivide(_rhs : Vector) : Vector
    {
        return divide(_rhs);
    }

    @:op(A + B) inline public function opAddScalar(_rhs : Float) : Vector
    {
        return addScalar(_rhs);
    }

    @:op(A - B) inline public function opSubtractScalar(_rhs : Float) : Vector
    {
        return subtractScalar(_rhs);
    }

    @:op(A * B) inline public function opMultiplyScalar(_rhs : Float) : Vector
    {
        return multiplyScalar(_rhs);
    }

    @:op(A / B) inline public function opDivideScalar(_rhs : Float) : Vector
    {
        return divideScalar(_rhs);
    }

    // #endregion

    /**
     * Sets all four components of the vector.
     * @param _x x value of the vector.
     * @param _y y value of the vector.
     * @param _z z value of the vector.
     * @param _w w value of the vector.
     * @return Vector
     */
    inline public function set(_x : Float, _y : Float, _z : Float, _w : Float) : Vector
    {
        x = _x;
        y = _y;
        z = _z;
        w = _w;

        return this;
    }

    /**
     * Sets the x, y, and z components of the vector.
     * @param _x x value of the vector.
     * @param _y y value of the vector.
     * @param _z z value of the vector.
     * @return Vector
     */
    inline public function set_xyz(_x : Float, _y : Float, _z : Float) : Vector
    {
        x = _x;
        y = _y;
        z = _z;

        return this;
    }

    /**
     * Sets the x and y components of the vector.
     * @param _x x value of the vector.
     * @param _y y value of the vector.
     * @return Vector
     */
    inline public function set_xy(_x : Float, _y : Float) : Vector
    {
        x = _x;
        y = _y;

        return this;
    }

    /**
     * Copies the component values from another vector into this one.
     * @param _other The vector to copy.
     * @return Vector
     */
    inline public function copyFrom(_other : Vector) : Vector
    {
        set(_other.x, _other.y, _other.z, _other.w);

        return this;
    }

    /**
     * Returns a string containing all four component values.
     * @return String
     */
    inline public function toString() : String
    {
        return ' { x : $x, y : $y, z : $z, w : $w } ';
    }

    /**
     * Checks if all four components of two vectors are equal.
     * @param _other The vector to check against.
     * @return Bool
     */
    inline public function equals(_other : Vector) : Bool
    {
        return (x == _other.x && y == _other.y && z == _other.z && w == _other.w);
    }

    /**
     * Returns a copy of this vector.
     * @return Vector
     */
    inline public function clone() : Vector
    {
        return new Vector(x, y, z, w);
    }

    // #region maths

    /**
     * Normalizes this vectors components.
     * @return Vector
     */
    inline public function normalize() : Vector
    {
        return divideScalar(length);
    }

    /**
     * Returns the doth product of this vector with another.
     * @param _other The other vector.
     * @return Float
     */
    inline public function dot(_other : Vector) : Float
    {
        return x * _other.x + y * _other.y + z * _other.z;
    }

    /**
     * Sets this vector to the cross product of two other vectors.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    inline public function cross(_v1 : Vector, _v2 : Vector) : Vector
    {
        set_xyz(_v1.y * _v2.z - _v1.z * _v2.y,
                _v1.z * _v2.x - _v1.x * _v2.z,
                _v1.x * _v2.y - _v1.y * _v2.x);

        return this;
    }

    /**
     * Inverts the x, y, and z components of this vector.
     * @return Vector
     */
    inline public function invert() : Vector
    {
        set_xyz(-x, -y, -z);

        return this;
    }

    // #endregion

    // #region operations

    /**
     * Adds another vector onto this one.
     * @param _other The vector to add.
     * @return Vector
     */
    inline public function add(_other : Vector) : Vector
    {
        set_xyz(x + _other.x, y + _other.y, z + _other.z);

        return this;
    }

    /**
     * Adds values to this vectors components.
     * @param _x The value to add to the x component.
     * @param _y The value to add to the y component.
     * @param _z The value to add to the z component.
     * @return Vector
     */
    inline public function add_xyz(_x : Float, _y : Float, _z : Float) : Vector
    {
        set_xyz(x + _x, y + _y, z + _z);

        return this;
    }

    /**
     * Subtracts another vector from this one.
     * @param _other The vector to subtract.
     * @return Vector
     */
    inline public function subtract(_other : Vector) : Vector
    {
        set_xyz(x - _other.x, y - _other.y, z - _other.z);

        return this;
    }

    /**
     * Subtracts values from this vectors components.
     * @param _x The value to subtract from the x component.
     * @param _y The value to subtract from the y component.
     * @param _z The value to subtract from the z component.
     * @return Vector
     */
    inline public function subtract_xyz(_x : Float, _y : Float, _z : Float) : Vector
    {
        set_xyz(x - _x, y - _y, z - _z);

        return this;
    }

    /**
     * Multiplies this vector with another.
     * @param _other Vector to multiply by.
     * @return Vector
     */
    inline public function multiply(_other : Vector) : Vector
    {
        set_xyz(x * _other.x, y * _other.y, z * _other.z);

        return this;
    }

    /**
     * Multiply each of this vectors components with a separate value.
     * @param _x Value to multiply the x component by.
     * @param _y Value to multiply the y component by.
     * @param _z Value to multiply the z component by.
     * @return Vector
     */
    inline public function multiply_xyz(_x : Float, _y : Float, _z : Float) : Vector
    {
        set_xyz(x * _x, y * _y, z * _z);

        return this;
    }

    /**
     * Divide this vector by another.
     * @param _other Vector to divide by.
     * @return Vector
     */
    inline public function divide(_other : Vector) : Vector
    {
        set_xyz(x / _other.x, y / _other.y, z / _other.z);

        return this;
    }

    /**
     * Divide each of this vectors components with by a separate value.
     * @param _x Value to divide the x component by.
     * @param _y Value to divide the y component by.
     * @param _z Value to divide the z component by.
     * @return Vector
     */
    inline public function divide_xyz(_x : Float, _y : Float, _z : Float) : Vector
    {
        set_xyz(x / _x, y / _y, z / _z);

        return this;
    }

    /**
     * Adds a scalar value to all three vector components.
     * @param _v Constant scalar value.
     * @return Vector
     */
    inline public function addScalar(_v : Float) : Vector
    {
        set_xyz(x + _v, y + _v, z + _v);

        return this;
    }

    /**
     * Subtracts a scalar value from all three vector components.
     * @param _v Constant scalar value.
     * @return Vector
     */
    inline public function subtractScalar(_v : Float) : Vector
    {
        set_xyz(x - _v, y - _v, z - _v);

        return this;
    }

    /**
     * Multiplies all three vector components by a constant scalar.
     * @param _v Scalar value to multiply by.
     * @return Vector
     */
    inline public function multiplyScalar(_v : Float) : Vector
    {
        set_xyz(x * _v, y * _v, z * _v);

        return this;
    }

    /**
     * Divide all three vector components by a constant scalar.
     * If the scalar value is zero the vector components are all set to zero.
     * @param _v Scalar value to divide by.
     * @return Vector
     */
    inline public function divideScalar(_v : Float) : Vector
    {
        if (_v != 0)
        {
            set_xyz(x / _v, y / _v, z / _v);
        }
        else
        {
            set_xyz(0, 0, 0);
        }

        return this;
    }

    // #endregion

    // #region transforms

    /**
     * Transform this vector according to a matrix.
     * @param _m Matrix to transform by.
     * @return Vector
     */
    inline public function transform(_m : Matrix) : Vector
    {
        set_xyz(_m[0] * x + _m[4] * y + _m[ 8] * z + _m[12],
                _m[1] * x + _m[5] * y + _m[ 9] * z + _m[13],
                _m[2] * x + _m[6] * y + _m[10] * z + _m[14]);

        return this;
    }

    /**
     * Sets this vector to the euler angles of a quaternion.
     * @param _q Quaternion to read angles from.
     * @param _order Order of the quaternions components. (default XYZ)
     * @return Vector
     */
    inline public function setEulerFromQuaternion(_q : Quaternion, _order : ComponentOrder = XYZ) : Vector
    {
        var sqx = _q.x * _q.x;
        var sqy = _q.y * _q.y;
        var sqz = _q.z * _q.z;
        var sqw = _q.w * _q.w;

        var _x = x;
        var _y = y;
        var _z = z;

        switch (_order)
        {
            case XYZ:
                _x = Maths.atan2(2 * (_q.x * _q.w - _q.y * _q.z), (sqw - sqx - sqy + sqz));
                _y = Maths.asin(Maths.clamp(2 * (_q.x * _q.z + _q.y * _q.w), -1, 1));
                _z = Maths.atan2(2 * (_q.z * _q.w - _q.x * _q.y), (sqw + sqx - sqy - sqz));
            case YXZ:
                _x = Maths.asin(Maths.clamp(2 * (_q.x * _q.w - _q.y * _q.z), -1, 1));
                _y = Maths.atan2(2 * (_q.x * _q.z + _q.y * _q.w), (sqw - sqx - sqy + sqz));
                _y = Maths.atan2(2 * (_q.x * _q.z + _q.y * _q.w), (sqw - sqx + sqy - sqz));
            case ZXY:
                _x = Maths.asin(Maths.clamp(2 * (_q.x * _q.w + _q.y * _q.z), -1, 1));
                _y = Maths.atan2(2 * (_q.y * _q.w - _q.z * _q.x), (sqw - sqx - sqy + sqz));
                _y = Maths.atan2(2 * (_q.z * _q.w - _q.x * _q.y), (sqw - sqx + sqy - sqz));
            case ZYX:
                _x = Maths.atan2(2 * (_q.x * _q.w - _q.z * _q.y), (sqw - sqx + sqy - sqz));
                _y = Maths.asin(Maths.clamp(2 * (_q.y * _q.w - _q.x * _q.z), -1, 1));
                _z = Maths.atan2(2 * (_q.x * _q.y + _q.z * _q.w), (sqw + sqx - sqy - sqz));
            case YZX:
                _x = Maths.atan2(2 * (_q.x * _q.w - _q.z * _q.y), (sqw - sqx + sqy - sqz));
                _y = Maths.atan2(2 * (_q.y * _q.w - _q.x * _q.z), (sqw + sqx + sqy - sqz));
                _z = Maths.asin(Maths.clamp(2 * (_q.x * _q.y + _q.z * _q.w), -1, 1));
            case XZY:
                _x = Maths.atan2(2 * (_q.x * _q.w + _q.y * _q.z), (sqw - sqx + sqy - sqz));
                _y = Maths.atan2(2 * (_q.x * _q.z + _q.y * _q.w), (sqw + sqx - sqy - sqz));
                _z = Maths.asin(Maths.clamp(2 * (_q.z * _q.w - _q.x * _q.y), -1, 1));
        }

        return set_xyz(_x, _y, _z);
    }

    // #endregion

    // #region static functions

    /**
     * Adds two vectors together and stores the result in a new vector.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    inline public static function Add(_v1 : Vector, _v2 : Vector) : Vector
    {
        return new Vector(_v1.x + _v2.x, _v1.y + _v2.y, _v1.z + _v2.z);
    }

    /**
     * Subtracts two vectors and stores the result in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    inline public static function Subtract(_v1 : Vector, _v2 : Vector) : Vector
    {
        return new Vector(_v1.x - _v2.x, _v1.y - _v2.y, _v1.z - _v2.z);
    }

    /**
     * Multiplies two vectors together and stores the results in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    inline public static function Multiply(_v1 : Vector, _v2 : Vector) : Vector
    {
        return new Vector(_v1.x * _v2.x, _v1.y * _v2.y, _v1.z * _v2.z);
    }

    /**
     * Divides one vector by another and stores the result in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    inline public static function Divide(_v1 : Vector, _v2 : Vector) : Vector
    {
        return new Vector(_v1.x / _v2.x, _v1.y / _v2.y, _v1.z / _v2.z);
    }

    /**
     * Adds a scalar value to a vector and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    inline public static function AddScalar(_v : Vector, _f : Float) : Vector
    {
        return new Vector(_v.x + _f, _v.y + _f, _v.z + _f);
    }

    /**
     * Subtract a scalar value from a vector and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    inline public static function SubtractScalar(_v : Vector, _f : Float) : Vector
    {
        return new Vector(_v.x - _f, _v.y - _f, _v.z - _f);
    }

    /**
     * Multiply a vector by a scalar value and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    inline public static function MultiplyScalar(_v : Vector, _f : Float) : Vector
    {
        return new Vector(_v.x * _f, _v.y * _f, _v.z * _f);
    }

    /**
     * Divide a vector by a scalar value and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    inline public static function DivideScalar(_v : Vector, _f : Float) : Vector
    {
        return new Vector(_v.x / _f, _v.y / _f, _v.z / _f);
    }

    /**
     * Calculate the cross product between two vectors, storing the result in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    inline public static function Cross(_v1 : Vector, _v2 : Vector) : Vector
    {
        return new Vector(_v1.y * _v2.z - _v1.z * _v2.y,
                          _v1.z * _v2.x - _v1.x * _v2.z,
                          _v1.x * _v2.y - _v1.y * _v2.x);
    }

    // #endregion
}
