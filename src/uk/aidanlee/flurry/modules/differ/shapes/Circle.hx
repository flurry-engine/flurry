package uk.aidanlee.flurry.modules.differ.shapes;

import uk.aidanlee.flurry.modules.differ.data.*;
import uk.aidanlee.flurry.modules.differ.sat.SAT2D;

/**
 * A circle collision shape
 */
class Circle extends Shape
{
    /**
     * The radius of this circle. Set on construction.
     */
    public final radius : Float;

    /**
     * The transformed radius of this circle, based on the scale/rotation
     */
    public var transformedRadius (get, never) : Float;

    inline function get_transformedRadius() : Float {
        return radius * scaleX;
    }

    public function new(_x : Float, _y : Float, _radius : Float)
    {
        super(_x, _y, 'circle $_radius');

        radius = _radius;
    }

    /**
     * Test for collision against a shape.
     */
    override public function test(_shape : Shape, ?_into : Null<ShapeCollision>) : Null<ShapeCollision>
    {
        return _shape.testCircle(this, _into, true);
    }

    /**
     * Test for collision against a circle.
     */
    override public function testCircle(_circle : Circle, ?_into : Null<ShapeCollision>, _flip : Bool = false) : Null<ShapeCollision>
    {
        return SAT2D.testCircleVsCircle(this, _circle, _into, _flip);
    }

    /**
     * Test for collision against a polygon.
     */
    override public function testPolygon(_polygon : Polygon, ?_into : Null<ShapeCollision>, _flip : Bool = false) : Null<ShapeCollision>
    {
        return SAT2D.testCircleVsPolygon(this, _polygon, _into, _flip);
    }

    /** Test for collision against a ray. */
    override public function testRay(_ray : Ray, ?_into : Null<RayCollision>) : Null<RayCollision>
    {
        return SAT2D.testRayVsCircle(_ray, this, _into);
    }
}
