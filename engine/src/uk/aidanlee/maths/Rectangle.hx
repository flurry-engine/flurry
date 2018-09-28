package uk.aidanlee.maths;

import snow.api.Emitter;

enum abstract EvRectangle(Int) from Int to Int
{
    /**
     * This event is emitted whenever the size of the rectangle changes.
     */
    var ChangedSize;
}

class Rectangle
{
    /**
     * Event emitter for this rectangle.
     */
    public final events : Emitter<EvRectangle>;

    /**
     * The top left x position of this rectangle.
     */
    public var x (default, set) : Float;

    inline function set_x(_x : Float) : Float {
        emitChange();

        return x = _x;
    }

    /**
     * The top left y position of this rectangle.
     */
    public var y (default, set) : Float;

    inline function set_y(_y : Float) : Float {
        emitChange();

        return y = _y;
    }

    /**
     * The width of this rectangle.
     */
    public var w (default, set) : Float;

    inline function set_w(_w : Float) : Float {
        emitChange();

        return w = _w;
    }

    /**
     * The height of this rectangle.
     */
    public var h (default, set) : Float;

    inline function set_h(_h : Float) : Float {
        emitChange();

        return h = _h;
    }

    /**
     * If set to true events will not be fired from setter functions.
     * This is useful for the non setter functions as we can send one event instead of several.
     */
    var ignoreListeners : Bool;

    /**
     * Create a new rectangle instance.
     * @param _x Top left x position of the rectangle.
     * @param _y Top left y position of the rectangle.
     * @param _w Width of the rectangle.
     * @param _w Height of the rectangle.
     */
    inline public function new(_x : Float = 0, _y : Float = 0, _w : Float = 0, _h : Float = 0)
    {
        events = new Emitter();

        x = _x;
        y = _y;
        w = _w;
        h = _h;

        ignoreListeners = false;
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
        ignoreListeners = true;

        x = _x;
        y = _y;
        w = _w;
        h = _h;

        ignoreListeners = false;

        emitChange();

        return this;
    }

    /**
     * Set this rectangle to the size of another.
     * @param _other Rectangle to copy.
     * @return Rectangle
     */
    inline public function copyFrom(_other : Rectangle) : Rectangle
    {
        ignoreListeners = true;

        x = _other.x;
        y = _other.y;
        w = _other.w;
        h = _other.h;

        ignoreListeners = false;

        emitChange();

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

    // #endregion

    /**
     * Convenience inlined function to emit a size changed event.
     */
    inline function emitChange()
    {
        if (ignoreListeners) return;

        events.emit(ChangedSize);
    }
}
