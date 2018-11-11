package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import snow.api.Debug.def;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;

typedef QuadGeometryOptions = {
    >GeometryOptions,

    var ?x : Float;
    var ?y : Float;
    var ?w : Float;
    var ?h : Float;
    var ?uv : Rectangle;
}

/**
 * Quad geometry for quickly displaying a UV'd texture using six vertices.
 */
class QuadGeometry extends Geometry
{
    public function new(_options : QuadGeometryOptions)
    {
        super(_options);

        _options.x  = def(_options.x, 0);
        _options.y  = def(_options.y, 0);
        _options.w  = def(_options.w, textures[0].width );
        _options.h  = def(_options.h, textures[0].height);
        _options.uv = def(_options.uv, new Rectangle(0, 0, 1, 1));

        vertices.resize(4);
        vertices[0] = new Vertex( new Vector(         0, _options.h), color, new Vector(_options.uv.x, _options.uv.h) );
        vertices[1] = new Vertex( new Vector(_options.w, _options.h), color, new Vector(_options.uv.w, _options.uv.h) );
        vertices[2] = new Vertex( new Vector(         0,          0), color, new Vector(_options.uv.x, _options.uv.y) );
        vertices[3] = new Vertex( new Vector(_options.w,          0), color, new Vector(_options.uv.w, _options.uv.y) );

        indices.resize(6);
        indices[0] = 0;
        indices[1] = 1;
        indices[2] = 2;
        indices[3] = 2;
        indices[4] = 1;
        indices[5] = 3;

        transformation.position.set_xy(_options.x, _options.y);
    }

    /**
     * Resize the quad according to a vector.
     * @param _vector New width and height of the quad.
     */
    public function resize(_vector : Vector)
    {
        vertices[0].position.set_xy(        0, _vector.y);
        vertices[1].position.set_xy(_vector.x, _vector.y);
        vertices[2].position.set_xy(        0,         0);
        vertices[3].position.set_xy(_vector.x,         0);
    }

    /**
     * Resize the quad according to two floats.
     * @param _x New width of the quad.
     * @param _y New height of the quad.
     */
    public function resize_xy(_x : Float, _y : Float)
    {
        vertices[0].position.set_xy( 0, _y);
        vertices[1].position.set_xy(_x, _y);
        vertices[2].position.set_xy( 0,  0);
        vertices[3].position.set_xy(_x,  0);
    }

    /**
     * Set the position and size of the quad from a rectangle.
     * @param _rectangle Rectangle containing the new position and size.
     */
    public function set(_rectangle : Rectangle)
    {
        vertices[0].position.set_xy(           0, _rectangle.h);
        vertices[1].position.set_xy(_rectangle.w, _rectangle.h);
        vertices[2].position.set_xy(           0,            0);
        vertices[3].position.set_xy(_rectangle.w,            0);

        transformation.position.set_xy(_rectangle.x, _rectangle.y);
    }

    /**
     * Set the position and size of the quad from four floats.
     * @param _x New x position of the quad.
     * @param _y New y position of the quad.
     * @param _w New width of the quad.
     * @param _h New height of the quad.
     */
    public function set_xywh(_x : Float, _y : Float, _w : Float, _h : Float)
    {
        vertices[0].position.set_xy( 0, _h);
        vertices[1].position.set_xy(_w, _h);
        vertices[2].position.set_xy( 0,  0);
        vertices[3].position.set_xy(_w,  0);

        transformation.position.set_xy(_x, _y);
    }

    /**
     * Set the UV coordinates of the quad from a rectangle.
     * The w and h components make the bottom right point of the UV rectangle. They are not used as offsets from the x and y position.
     * Normalized and texture space coordinates are supported. Texture space coordinates will be converted to normalized coordinates.
     * @param _uv         UV rectangle.
     * @param _normalized If the values are already normalized. (defaults true)
     */
    public function uv(_uv : Rectangle, _normalized : Bool = true)
    {
        var uv_x = _normalized ? _uv.x : _uv.x / textures[0].width;
        var uv_y = _normalized ? _uv.y : _uv.y / textures[0].height;
        var uv_w = _normalized ? _uv.w : _uv.w / textures[0].width;
        var uv_h = _normalized ? _uv.h : _uv.h / textures[0].height;

        vertices[0].position.set_xy(uv_x, uv_h);
        vertices[1].position.set_xy(uv_w, uv_h);
        vertices[2].position.set_xy(uv_x, uv_y);
        vertices[3].position.set_xy(uv_w, uv_y);
    }

    /**
     * Set the UV coordinates of the quad from four floats.
     * Normalized and texture space coordinates are supported. Texture space coordinates will be converted to normalized coordinates.
     * @param _x Top left x coordinate.
     * @param _y Top left y coordinate.
     * @param _z Bottom right x coordinate.
     * @param _w Bottom right y coordinate.
     * @param _normalized 
     */
    public function uv_xyzw(_x : Float, _y : Float, _z : Float, _w : Float, _normalized : Bool = true)
    {
        var uv_x = _normalized ? _x : _x / textures[0].width;
        var uv_y = _normalized ? _y : _y / textures[0].height;
        var uv_w = _normalized ? _z : _z / textures[0].width;
        var uv_h = _normalized ? _w : _w / textures[0].height;

        vertices[0].position.set_xy(uv_x, uv_h);
        vertices[1].position.set_xy(uv_w, uv_h);
        vertices[2].position.set_xy(uv_x, uv_y);
        vertices[3].position.set_xy(uv_w, uv_y);
    }
}
