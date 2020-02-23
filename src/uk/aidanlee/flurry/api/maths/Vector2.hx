package uk.aidanlee.flurry.api.maths;

import uk.aidanlee.flurry.api.buffers.Float32BufferData;

/**
 * Vector class which contains an x and y component.
 */
@:forward(subscribe)
abstract Vector2(Float32BufferData) from Float32BufferData to Float32BufferData from Vector2
{
    /**
     * x component of this vector.
     */
    public var x (get, set) : Float;

    inline function get_x() : Float return this[0];

    inline function set_x(_x : Float) : Float return this[0] = _x;

    /**
     * y component of this vector.
     */
    public var y (get, set) : Float;

    inline function get_y() : Float return this[1];

    inline function set_y(_y : Float) : Float return this[1] = _y;

    /**
     * The length of this vector.
     */
    public var length (get, never) : Float;

    inline function get_length() : Float return Maths.sqrt(x * x + y * y);

    /**
     * The square of this vectors length.
     */
    public var lengthsq (get, never) : Float;

    inline function get_lengthsq() : Float return x * x + y * y;

    /**
     * The 2D angle this vector represents.
     */
    public var angle2D (get, never) : Float;

    inline function get_angle2D() : Float return Maths.atan2(y, x);

    /**
     * Normalized version of this vector.
     */
    public var normalized (get, never) : Vector2;

    inline function get_normalized() : Vector2 return new Vector2(x / length, y / length);

    /**
     * Inverted version of this vector.
     */
    public var inverted (get, never) : Vector2;

    inline function get_inverted() : Vector2 return new Vector2(-x, -y);

    /**
     * Create a new vector instance.
     * @param _x x value of the vector.
     * @param _y y value of the vector.
     */
    public function new(_x : Float = 0, _y : Float = 0)
    {
        this = new Float32BufferData(2);

        x = _x;
        y = _y;
    }

    // #region overloaded operators

    @:op(A + B) public inline function opAdd(_rhs : Vector2) : Vector2
    {
        return add(_rhs);
    }

    @:op(A - B) public inline function opSubtract(_rhs : Vector2) : Vector2
    {
        return subtract(_rhs);
    }

    @:op(A * B) public inline function opMultiply(_rhs : Vector2) : Vector2
    {
        return multiply(_rhs);
    }

    @:op(A / B) public inline function opDivide(_rhs : Vector2) : Vector2
    {
        return divide(_rhs);
    }

    @:op(A + B) public inline function opAddScalar(_rhs : Float) : Vector2
    {
        return addScalar(_rhs);
    }

    @:op(A - B) public inline function opSubtractScalar(_rhs : Float) : Vector2
    {
        return subtractScalar(_rhs);
    }

    @:op(A * B) public inline function opMultiplyScalar(_rhs : Float) : Vector2
    {
        return multiplyScalar(_rhs);
    }

    @:op(A / B) public inline function opDivideScalar(_rhs : Float) : Vector2
    {
        return divideScalar(_rhs);
    }

    // #endregion

    /**
     * Sets all four components of the vector.
     * @param _x x value of the vector.
     * @param _y y value of the vector.
     * @return Vector2
     */
    public function set(_x : Float, _y : Float) : Vector2
    {
        x = _x;
        y = _y;

        return this;
    }

    /**
     * Copies the component values from another vector into this one.
     * @param _other The vector to copy.
     * @return Vector2
     */
    public function copyFrom(_other : Vector2) : Vector2
    {
        set(_other.x, _other.y);

        return this;
    }

    /**
     * Returns a string containing all four component values.
     * @return String
     */
    public function toString() : String
    {
        return ' { x : $x, y : $y } ';
    }

    /**
     * Checks if all four components of two vectors are equal.
     * @param _other The vector to check against.
     * @return Bool
     */
    public function equals(_other : Vector2) : Bool
    {
        return x == _other.x && y == _other.y;
    }

    /**
     * Returns a copy of this vector.
     * @return Vector
     */
    public function clone() : Vector2
    {
        return new Vector2(x, y);
    }

    // #region maths

    /**
     * Normalizes this vectors components.
     * @return Vector
     */
    public function normalize() : Vector2
    {
        return divideScalar(length);
    }

    /**
     * Inverts the x, y, and z components of this vector.
     * @return Vector
     */
    public function invert() : Vector2
    {
        return set(-x, -y);
    }

    // #endregion

    // #region operations

    /**
     * Adds another vector onto this one.
     * @param _other The vector to add.
     * @return Vector
     */
    public function add(_other : Vector2) : Vector2
    {
        return set(x + _other.x, y + _other.y);
    }

    /**
     * Adds values to this vectors components.
     * @param _x The value to add to the x component.
     * @param _y The value to add to the y component.
     * @return Vector
     */
    public function add_xy(_x : Float, _y : Float) : Vector2
    {
        return set(x + _x, y + _y);
    }

    /**
     * Subtracts another vector from this one.
     * @param _other The vector to subtract.
     * @return Vector
     */
    public function subtract(_other : Vector2) : Vector2
    {
        return set(x - _other.x, y - _other.y);
    }

    /**
     * Subtracts values from this vectors components.
     * @param _x The value to subtract from the x component.
     * @param _z The value to subtract from the z component.
     * @return Vector
     */
    public function subtract_xy(_x : Float, _y : Float) : Vector2
    {
        return set(x - _x, y - _y);
    }

    /**
     * Multiplies this vector with another.
     * @param _other Vector to multiply by.
     * @return Vector
     */
    public function multiply(_other : Vector2) : Vector2
    {
        return set(x * _other.x, y * _other.y);
    }

    /**
     * Multiply each of this vectors components with a separate value.
     * @param _x Value to multiply the x component by.
     * @param _y Value to multiply the y component by.
     * @return Vector
     */
    public function multiply_xy(_x : Float, _y : Float) : Vector2
    {
        return set(x * _x, y * _y);
    }

    /**
     * Divide this vector by another.
     * @param _other Vector to divide by.
     * @return Vector
     */
    public function divide(_other : Vector2) : Vector2
    {
        return set(x / _other.x, y / _other.y);
    }

    /**
     * Divide each of this vectors components with by a separate value.
     * @param _x Value to divide the x component by.
     * @param _y Value to divide the y component by.
     * @return Vector
     */
    public function divide_xy(_x : Float, _y : Float) : Vector2
    {
        return set(x / _x, y / _y);
    }

    /**
     * Adds a scalar value to all three vector components.
     * @param _v Constant scalar value.
     * @return Vector
     */
    public function addScalar(_v : Float) : Vector2
    {
        return set(x + _v, y + _v);
    }

    /**
     * Subtracts a scalar value from all three vector components.
     * @param _v Constant scalar value.
     * @return Vector
     */
    public function subtractScalar(_v : Float) : Vector2
    {
        return set(x - _v, y - _v);
    }

    /**
     * Multiplies all three vector components by a constant scalar.
     * @param _v Scalar value to multiply by.
     * @return Vector
     */
    public function multiplyScalar(_v : Float) : Vector2
    {
        return set(x * _v, y * _v);
    }

    /**
     * Divide all three vector components by a constant scalar.
     * If the scalar value is zero the vector components are all set to zero.
     * @param _v Scalar value to divide by.
     * @return Vector
     */
    public function divideScalar(_v : Float) : Vector2
    {
        if (_v != 0)
        {
            set(x / _v, y / _v);
        }
        else
        {
            set(0, 0);
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
    public function transform(_m : Matrix) : Vector2
    {
        return set(
            (x * _m.m11) + (y * _m.m12) + _m.m14,
            (x * _m.m21) + (y * _m.m22) + _m.m24
        );
    }

    // #endregion

    // #region static functions

    /**
     * Adds two vectors together and stores the result in a new vector.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    public static function Add(_v1 : Vector2, _v2 : Vector2) : Vector2
    {
        return new Vector2(_v1.x + _v2.x, _v1.y + _v2.y);
    }

    /**
     * Subtracts two vectors and stores the result in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    public static function Subtract(_v1 : Vector2, _v2 : Vector2) : Vector2
    {
        return new Vector2(_v1.x - _v2.x, _v1.y - _v2.y);
    }

    /**
     * Multiplies two vectors together and stores the results in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    public static function Multiply(_v1 : Vector2, _v2 : Vector2) : Vector2
    {
        return new Vector2(_v1.x * _v2.x, _v1.y * _v2.y);
    }

    /**
     * Divides one vector by another and stores the result in a new vector.
     * Original vectors remain unchanged.
     * @param _v1 First vector.
     * @param _v2 Second vector.
     * @return Vector
     */
    public static function Divide(_v1 : Vector2, _v2 : Vector2) : Vector2
    {
        return new Vector2(_v1.x / _v2.x, _v1.y / _v2.y);
    }

    /**
     * Adds a scalar value to a vector and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    public static function AddScalar(_v : Vector2, _f : Float) : Vector2
    {
        return new Vector2(_v.x + _f, _v.y + _f);
    }

    /**
     * Subtract a scalar value from a vector and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    public static function SubtractScalar(_v : Vector2, _f : Float) : Vector2
    {
        return new Vector2(_v.x - _f, _v.y - _f);
    }

    /**
     * Multiply a vector by a scalar value and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    public static function MultiplyScalar(_v : Vector2, _f : Float) : Vector2
    {
        return new Vector2(_v.x * _f, _v.y * _f);
    }

    /**
     * Divide a vector by a scalar value and store the result in a new vector.
     * Original vector remains unchanged.
     * @param _v Vector instance.
     * @param _f Scalar value.
     * @return Vector
     */
    public static function DivideScalar(_v : Vector2, _f : Float) : Vector2
    {
        return new Vector2(_v.x / _f, _v.y / _f);
    }

    // #endregion
}
