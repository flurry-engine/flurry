package uk.aidanlee.flurry.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.modules.differ.data.*;

class Shape
{
    /**
     * The name of this shape, to help in debugging.
     */
    public final name : String;

    /**
     * The state of this shape, if inactive can be ignored in results
     */
    public var active : Bool;

    /**
     * The x position of this shape
     */
    public var x (get, set) : Float;

    inline function get_x() : Float {
        return position.x;
    }

    inline function set_x(_x : Float) : Float {        
        position.x = _x;

        refreshTransform();

        return position.x;
    }

    /**
     * The y position of this shape
     */
    public var y (get, set) : Float;

    inline function get_y() : Float {
        return position.y;
    }

    inline function set_y(_y : Float) : Float {
        position.y = _y;

        refreshTransform();

        return position.y;
    }

    /**
     * The rotation of this shape, in degrees
     */
    public var rotation (default, set) : Float;

    inline function set_rotation(_v : Float) : Float {
        rotationRadians = _v * (Math.PI / 180);

        refreshTransform();

        return rotation = _v;
    }

    /**
     * The scale in the x direction of this shape
     */
    public var scaleX (get, set) : Float;

    inline function get_scaleX() : Float {
        return scale.x;
    }

    inline function set_scaleX(_scale : Float) : Float {
        scale.x = _scale;

        refreshTransform();

        return scale.x;
    }

    /**
     * The scale in the y direction of this shape
     */
    public var scaleY (get, set) : Float;

    function get_scaleY() : Float {
        return scale.y;
    }

    function set_scaleY(_scale : Float) : Float {
        scale.y = _scale;

        refreshTransform();

        return scale.y;
    }

    final position : Vector;
    final scale : Vector;
    final transformMatrix : Matrix;
    final transformQuaternion : Quaternion;
    final transformRotation : Vector;
    var rotationRadians : Float;
    var transformed : Bool;

    /**
     * Create a new shape at give position x, y
     */
    public function new(_x : Float, _y : Float, _name : String = 'shape')
    {
        name                = _name;
        active              = true;
        position            = new Vector(_x, _y);
        scale               = new Vector(1, 1);
        transformMatrix     = new Matrix().makeTranslation(x, y, 0);
        transformQuaternion = new Quaternion();
        transformRotation   = new Vector(0, 0, 1);
        rotation            = 0;
        rotationRadians     = 0;
        transformed         = false;
    }

    /**
     * Test this shape against another shape
     */
    public function test(_shape : Shape, ?_into : Null<ShapeCollision>) : Null<ShapeCollision> return null;

    /**
     * Test this shape against a circle.
     */
    public function testCircle(_circle : Circle, ?_into : Null<ShapeCollision>, _flip : Bool = false) : Null<ShapeCollision> return null;

    /**
     * Test this shape against a polygon.
     */
    public function testPolygon(_polygon : Polygon, ?_into : Null<ShapeCollision>, _flip : Bool = false) : Null<ShapeCollision> return null;

    /**
     * Test this shape against a ray.
     */
    public function testRay(_ray : Ray, ?_into : Null<RayCollision>) : Null<RayCollision> return null;

    function refreshTransform()
    {
        transformMatrix.compose(position, transformQuaternion.setFromAxisAngle(transformRotation, rotationRadians), scale);
        transformed = false;
    }
}
