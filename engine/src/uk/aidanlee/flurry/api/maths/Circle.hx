package uk.aidanlee.flurry.api.maths;

class Circle
{
    /**
     * The x position of the circle.
     */
    public var x : Float;

    /**
     * The y position of the circle.
     */
    public var y : Float;

    /**
     * The radium of the circle.
     */
    public var r : Float;

    /**
     * Create a new circle.
     * @param _x x position.
     * @param _y y position.
     * @param _r radius.
     */
    public inline function new(_x : Float = 0, _y : Float = 0, _r : Float = 0)
    {
        x = _x;
        y = _y;
        r = _r;
    }

    // #region general

    /**
     * Sets the position and radius of the circle.
     * @param _x x position.
     * @param _y y position.
     * @param _r radius.
     * @return Circle
     */
    public inline function set(_x : Float, _y : Float, _r : Float) : Circle
    {
        x = _x;
        y = _y;
        r = _r;

        return this;
    }

    /**
     * Copy the position and radius from another circle.
     * @param _other Circle to copy.
     * @return Circle
     */
    public inline function copyFrom(_other : Circle) : Circle
    {
        x = _other.x;
        y = _other.y;
        r = _other.r;

        return this;
    }

    /**
     * Clones this circle.
     * @return Circle
     */
    public inline function clone() : Circle
    {
        return new Circle(x, y, r);
    }

    // #endregion

    // #region maths

    /**
     * Checks if a vector is within this circle.
     * @param _p Vector to check.
     * @return Bool
     */
    public inline function containsPoint(_p : Vector) : Bool
    {
        var dx = _p.x - x;
        var dy = _p.y - y;
        var len = Math.sqrt(dx * dx + dy * dy);

        return len <= r;
    }

    // #endregion
}
