package uk.aidanlee.flurry.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.modules.differ.data.*;
import uk.aidanlee.flurry.modules.differ.sat.SAT2D;

/**
 * A polygonal collision shape
 */
class Polygon extends Shape
{
    /**
     * The transformed (scaled and rotated) vertices.
     */
    public var transformedVertices (get, null) : Array<Vector2>;

    inline function get_transformedVertices() : Array<Vector2>
    {
        if (!transformed || vertices.length != transformedVertices.length)
        {
            transformed = true;

            transformedVertices.resize(vertices.length);

            for (i in 0...vertices.length)
            {
                if (transformedVertices[i] == null)
                {
                    transformedVertices[i] = vertices[i].clone().transform(transformMatrix);
                }
                else
                {
                    transformedVertices[i].copyFrom(vertices[i]).transform(transformMatrix);
                }
            }
        }

        return transformedVertices;
    }

    /**
     * The vertices of this shape.
     */
    public final vertices : Array<Vector2>;

    /**
     * Create a new polygon with a given set of vertices at position x,y
     */
    public function new(_x : Float, _y : Float, _vertices : Array<Vector2>)
    {
        super(_x, _y, 'polygon(sides:${_vertices.length})');

        vertices            = _vertices;
        transformedVertices = [ for (v in vertices) v.clone() ];
    }

    /**
     * Test for a collision with a shape.
     */
    override public function test(_shape : Shape, _into : ShapeCollision = null) : Bool
    {
        return _shape.testPolygon(this, _into);
    }

    /**
     * Test for a collision with a circle.
     */
    override public function testCircle(_circle : Circle, _into : ShapeCollision = null) : Bool
    {
        return SAT2D.testCircleVsPolygon(_circle, this, _into, true);
    }

    /**
     * Test for a collision with a polygon.
     */
    override public function testPolygon(_polygon : Polygon, _into : ShapeCollision = null) : Bool
    {
        return SAT2D.testPolygonVsPolygon(this, _polygon, _into, false);
    }

    /**
     * Test for a collision with a ray.
     */
    override public function testRay(_ray : Ray, _into : RayCollision = null) : Bool
    {
        return SAT2D.testRayVsPolygon(_ray, this, _into);
    }

    /**
     * Helper to create an Ngon at x,y with given number of sides, and radius. A default radius of 100 if unspecified.
     * 
     * Returns a ready made `Polygon` collision `Shape`
     */
    public static function create(_x : Float, _y : Float, _sides : Int, _radius : Float = 100) : Polygon
    {
        if (_sides < 3)
        {
            throw 'Polygon - Needs at least 3 sides';
        }

        var rotation = (Math.PI * 2) / _sides;
        var angle    = 0.0;
        var verts    = [];

        for (i in 0..._sides)
        {
            angle = (i * rotation) + ((Math.PI - rotation) * 0.5);

            verts.push(new Vector2(Math.cos(angle) * _radius, Math.sin(angle) * _radius));
        }

        return new Polygon(_x, _y, verts);
    }

    /**
     * Helper generate a rectangle at x, y with a given width, height, and centered state.
     * 
     * Centered by default. Returns a ready made `Polygon` collision `Shape`
     */
    public static function rectangle(_x : Float, _y : Float, _width : Float, _height : Float, _centered : Bool = true) : Polygon
    {
        return new Polygon(_x, _y, _centered ? [
            new Vector2(-_width / 2, -_height / 2),
            new Vector2( _width / 2, -_height / 2),
            new Vector2( _width / 2,  _height / 2),
            new Vector2(-_width / 2,  _height / 2)
        ] : [
            new Vector2(     0,       0),
            new Vector2(_width,       0),
            new Vector2(_width, _height),
            new Vector2(     0, _height)
        ]);
    }

    /**
     * Helper generate a square at x,y with a given width/height with given centered state. Centered by default.
     * 
     * Returns a ready made `Polygon` collision `Shape`
     */
    public static function square(_x : Float, _y : Float, _width : Float, _centered : Bool = true) : Polygon
    {
        return rectangle(_x, _y, _width, _width, _centered);
    }

    /**
     * Helper generate a triangle at x,y with a given radius.
     * 
     * Returns a ready made `Polygon` collision `Shape`
     */
    public static function triangle(_x : Float, _y : Float, _radius : Float) : Polygon
    {
        return create(_x, _y, 3, _radius);
    }
}
