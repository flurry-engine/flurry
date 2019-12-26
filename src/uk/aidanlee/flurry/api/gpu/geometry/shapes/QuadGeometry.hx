package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.gpu.textures.ImageRegion;

using Safety;

typedef QuadGeometryOptions = {
    >GeometryOptions,

    var ?x : Float;
    var ?y : Float;
    var ?w : Float;
    var ?h : Float;
    var ?region : ImageRegion;
}

/**
 * Quad geometry for quickly displaying a UV'd texture using six vertices.
 */
class QuadGeometry extends Geometry
{
    public function new(_options : QuadGeometryOptions)
    {
        super(_options);

        _options.x  = _options.x.or(0);
        _options.y  = _options.y.or(0);
        _options.w  = _options.w.or(textures[0].width);
        _options.h  = _options.h.or(textures[0].height);

        final u1 = _options.region!.u1.or(0);
        final v1 = _options.region!.v1.or(0);
        final u2 = _options.region!.u2.or(1);
        final v2 = _options.region!.v2.or(1);

        vertices.resize(4);
        vertices[0] = new Vertex( new Vector3(         0, _options.h), color, new Vector2(u1, v2) );
        vertices[1] = new Vertex( new Vector3(_options.w, _options.h), color, new Vector2(u2, v2) );
        vertices[2] = new Vertex( new Vector3(         0,          0), color, new Vector2(u1, v1) );
        vertices[3] = new Vertex( new Vector3(_options.w,          0), color, new Vector2(u2, v1) );

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
    public function resize(_vector : Vector2)
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
    public function set_xywh(_x : Float, _y : Float, _width : Float, _height : Float)
    {
        vertices[0].position.set_xy(     0, _height);
        vertices[1].position.set_xy(_width, _height);
        vertices[2].position.set_xy(     0,  0);
        vertices[3].position.set_xy(_width,  0);

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

        vertices[0].texCoord.set(uv_x, uv_h);
        vertices[1].texCoord.set(uv_w, uv_h);
        vertices[2].texCoord.set(uv_x, uv_y);
        vertices[3].texCoord.set(uv_w, uv_y);
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

        vertices[0].texCoord.set(uv_x, uv_h);
        vertices[1].texCoord.set(uv_w, uv_h);
        vertices[2].texCoord.set(uv_x, uv_y);
        vertices[3].texCoord.set(uv_w, uv_y);
    }
}
