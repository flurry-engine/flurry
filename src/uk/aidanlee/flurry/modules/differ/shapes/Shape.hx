package uk.aidanlee.flurry.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;
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
    public var rotation (get, set) : Float;

    inline function get_rotation() : Float return rotationRadians * (180 / Math.PI);

    inline function set_rotation(_v : Float) : Float {
        rotationRadians = _v * (Math.PI / 180);

        refreshTransform();

        return rotationRadians;
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

    final position : Vector3;

    final scale : Vector3;

    final transformMatrix : Matrix;

    final transformQuaternion : Quaternion;
    
    final transformRotation : Vector3;

    var rotationRadians : Float;

    var transformed : Bool;

    /**
     * Create a new shape at give position x, y
     */
    public function new(_x : Float, _y : Float, _name : String = 'shape')
    {
        name                = _name;
        active              = true;
        transformed         = false;
        position            = new Vector3(_x, _y);
        scale               = new Vector3(1, 1);
        transformMatrix     = new Matrix().makeTranslation(_x, _y, 0);
        transformQuaternion = new Quaternion();
        transformRotation   = new Vector3(0, 0, 1);
        rotationRadians     = 0;
    }

    /**
     * Test this shape against another shape
     */
    public function test(_shape : Shape, _into : ShapeCollision = null) : Bool return false;

    /**
     * Test this shape against a circle.
     */
    public function testCircle(_circle : Circle, _into : ShapeCollision = null) : Bool return false;

    /**
     * Test this shape against a polygon.
     */
    public function testPolygon(_polygon : Polygon, _into : ShapeCollision = null) : Bool return false;

    /**
     * Test this shape against a ray.
     */
    public function testRay(_ray : Ray, _into : RayCollision = null) : Bool return false;

    function refreshTransform()
    {
        transformMatrix.compose(position, transformQuaternion.setFromAxisAngle(transformRotation, rotationRadians), scale);
        transformed = false;
    }
}
