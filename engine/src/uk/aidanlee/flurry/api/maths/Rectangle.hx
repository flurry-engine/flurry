package uk.aidanlee.flurry.api.maths;

class Rectangle
{
    /**
     * The top left x position of this rectangle.
     */
    public var x : Float;

    /**
     * The top left y position of this rectangle.
     */
    public var y : Float;

    /**
     * The width of this rectangle.
     */
    public var w : Float;

    /**
     * The height of this rectangle.
     */
    public var h : Float;

    /**
     * Create a new rectangle instance.
     * @param _x Top left x position of the rectangle.
     * @param _y Top left y position of the rectangle.
     * @param _w Width of the rectangle.
     * @param _w Height of the rectangle.
     */
    inline public function new(_x : Float = 0, _y : Float = 0, _w : Float = 0, _h : Float = 0)
    {
        x = _x;
        y = _y;
        w = _w;
        h = _h;
    }

    // #region general

    /**
     * Set the size of this rectangle.
     * @param _x Top left x position.
     * @param _y Top left y position.
     * @param _w Width.
     * @param _h Height.
     * @return Rectangle
     */
    inline public function set(_x : Float, _y : Float, _w : Float, _h : Float) : Rectangle
    {
        x = _x;
        y = _y;
        w = _w;
        h = _h;

        return this;
    }

    /**
     * Set this rectangle to the size of another.
     * @param _other Rectangle to copy.
     * @return Rectangle
     */
    inline public function copyFrom(_other : Rectangle) : Rectangle
    {
        x = _other.x;
        y = _other.y;
        w = _other.w;
        h = _other.h;

        return this;
    }

    /**
     * Check if this rectangle has an equal size to another.
     * @param _other Rectangle to check against.
     * @return Bool
     */
    inline public function equals(_other : Rectangle) : Bool
    {
        return x == _other.x && y == _other.y && w == _other.w && h == _other.h;
    }

    /**
     * Clone this rectangle.
     * @return Rectangle
     */
    inline public function clone() : Rectangle
    {
        return new Rectangle(x, y, w, h);
    }

    /**
     * Set the rectangle to have an area of 0 at 0x0.
     * @return Rectangle
     */
    inline public function clear() : Rectangle
    {
        return set(0, 0, 0, 0);
    }

    /**
     * Return a string representation of this rectangle.
     * @return String
     */
    inline public function toString() : String
    {
        return ' { x : $x, y : $y, w : $w, h : $h } ';
    }

    // #endregion

    // #region maths

    /**
     * Checks if a vector is within this rectangle.
     * @param _p Vector to check.
     * @return Bool
     */
    inline public function containsPoint(_p : Vector) : Bool
    {
        return _p.x > x && _p.y > y && _p.x < (x + w) && _p.y < (y + h);
    }

    /**
     * Checks if another rectangle overlaps with this one.
     * @param _other Rectangle to check.
     * @return Bool
     */
    inline public function overlaps(_other : Rectangle) : Bool
    {
        return x < (_other.x + _other.w) && y < (_other.y + _other.h) && (x + w) > _other.x && (y + h) > _other.y;
    }

    /**
     * Checks if another rectangle is entirely containing within this one.
     * @param _other Rectangle to check.
     * @return Bool
     */
    inline public function contains(_other : Rectangle) : Bool
    {
        return _other.x > x && _other.y > y && (_other.x + _other.w) < (x + w) && (_other.y + _other.h) < (y + h);
    }

    /**
     * Returns the area of this rectangle.
     * @return Float
     */
    inline public function area() : Float
    {
        return w * h;
    }

    // #endregion
}
