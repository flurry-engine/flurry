package uk.aidanlee.flurry.modules.differ.data;

import uk.aidanlee.flurry.modules.differ.shapes.Shape;

/**
 * Shape collision data obtained by testing two shapes for intersection.
 * `other` values are only filled when testing two `Polygon` shapes
 */
class ShapeCollision
{
    /**
     * The shape that was tested
     */
    public var shape1 (default, null) : Null<Shape>;

    /**
     * The shape that shape1 was tested against
     */
    public var shape2 (default, null) : Null<Shape>;

    /**
     * The overlap amount
     */
    public var overlap (default, null) : Float;

    /**
     * x component of the separation vector, when subtracted from shape 1 will separate it from shape 2
     */
    public var separationX (default, null) : Float;

    /**
     * y component of the separation vector, when subtracted from shape 1 will separate it from shape 2
     */
    public var separationY (default, null) : Float;

    /**
     * x component of the unit vector, on the axis of the collision (i.e the normal of the face that was collided with)
     */
    public var unitVectorX (default, null) : Float;

    /**
     * y component of the unit vector, on the axis of the collision (i.e the normal of the face that was collided with)
     */
    public var unitVectorY (default, null) : Float;

    public var otherOverlap (default, null) : Float;

    public var otherSeparationX (default, null) : Float;

    public var otherSeparationY (default, null) : Float;

    public var otherUnitVectorX (default, null) : Float;

    public var otherUnitVectorY (default, null) : Float;

    public function new(
        _shape1 : Shape = null,
        _shape2 : Shape = null,
        _overlap : Float = 0,
        _separationX : Float = 0,
        _separationY : Float = 0,
        _unitVectorX : Float = 0,
        _unitVectorY : Float = 0,
        _otherOverlap : Float = 0,
        _otherSeparationX : Float = 0,
        _otherSeparationY : Float = 0,
        _otherUnitVectorX : Float = 0,
        _otherUnitVectorY : Float = 0
    )
    {
        shape1           = _shape1;
        shape2           = _shape2;
        overlap          = _overlap;
        separationX      = _separationX;
        separationY      = _separationY;
        unitVectorX      = _unitVectorX;
        unitVectorY      = _unitVectorY;
        otherOverlap     = _otherOverlap;
        otherSeparationX = _otherSeparationX;
        otherSeparationY = _otherSeparationY;
        otherUnitVectorX = _otherUnitVectorX;
        otherUnitVectorY = _otherUnitVectorY;
    }

    public function set(
        _shape1 : Shape,
        _shape2 : Shape,
        _overlap : Float,
        _separationX : Float,
        _separationY : Float,
        _unitVectorX : Float,
        _unitVectorY : Float,
        _otherOverlap : Float,
        _otherSeparationX : Float,
        _otherSeparationY : Float,
        _otherUnitVectorX : Float,
        _otherUnitVectorY : Float
    ) : ShapeCollision
    {
        shape1           = _shape1;
        shape2           = _shape2;
        overlap          = _overlap;
        separationX      = _separationX;
        separationY      = _separationY;
        unitVectorX      = _unitVectorX;
        unitVectorY      = _unitVectorY;
        otherOverlap     = _otherOverlap;
        otherSeparationX = _otherSeparationX;
        otherSeparationY = _otherSeparationY;
        otherUnitVectorX = _otherUnitVectorX;
        otherUnitVectorY = _otherUnitVectorY;

        return this;
    }

    /**
     * Return a copy of itself.
     * The shapes in this collision are not cloned.
     * @return ShapeCollision
     */
    public function clone() : ShapeCollision
    {
        return new ShapeCollision(
            shape1,
            shape2,
            overlap,
            separationX,
            separationY,
            unitVectorX,
            unitVectorY,
            otherOverlap,
            otherSeparationX,
            otherSeparationY,
            otherUnitVectorX,
            otherUnitVectorY);
    }

    /**
     * Copy the values from another shape collision.
     * @param _other The shape collision to copy.
     * @return ShapeCollision
     */
    public function copyFrom(_other : ShapeCollision)
    {
        shape1           = _other.shape1;
        shape2           = _other.shape2;
        overlap          = _other.overlap;
        separationX      = _other.separationX;
        separationY      = _other.separationY;
        unitVectorX      = _other.unitVectorX;
        unitVectorY      = _other.unitVectorY;
        otherOverlap     = _other.otherOverlap;
        otherSeparationX = _other.otherSeparationX;
        otherSeparationY = _other.otherSeparationY;
        otherUnitVectorX = _other.otherUnitVectorX;
        otherUnitVectorY = _other.otherUnitVectorY;
    }
}