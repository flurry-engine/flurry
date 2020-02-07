package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Transformation;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob.IndexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.textures.ImageRegion;

using Safety;

typedef QuadGeometryOptions = {
    >GeometryOptions,

    var x : Float;
    var y : Float;
    var w : Float;
    var h : Float;
    var ?region : ImageRegion;
}

/**
 * Quad geometry for quickly displaying a UV'd texture using six vertices.
 */
class QuadGeometry extends Geometry
{
    public function new(_options : QuadGeometryOptions)
    {
        final u1 = _options.region!.u1.or(0);
        final v1 = _options.region!.v1.or(0);
        final u2 = _options.region!.u2.or(1);
        final v2 = _options.region!.v2.or(1);
        final tf = new Transformation();

        tf.position.set_xy(_options.x, _options.y);

        _options.data = Indexed(
            new VertexBlobBuilder()
                .addVertex(new Vector3(         0, _options.h), new Color(), new Vector2(u1, v2))
                .addVertex(new Vector3(_options.w, _options.h), new Color(), new Vector2(u2, v2))
                .addVertex(new Vector3(         0,          0), new Color(), new Vector2(u1, v1))
                .addVertex(new Vector3(_options.w,          0), new Color(), new Vector2(u2, v1))
                .vertexBlob(),
            new IndexBlobBuilder()
                .addArray([ 0, 1, 2, 2, 1, 3 ])
                .indexBlob()
        );
        _options.transform = tf;

        super(_options);
    }

    /**
     * Resize the quad according to a vector.
     * @param _vector New width and height of the quad.
     */
    public function resize(_vector : Vector2)
    {
        updateSize(_vector.x, _vector.y);
    }

    /**
     * Resize the quad according to two floats.
     * @param _x New width of the quad.
     * @param _y New height of the quad.
     */
    public function resize_xy(_x : Float, _y : Float)
    {
        updateSize(_x, _y);
    }

    /**
     * Set the position and size of the quad from a rectangle.
     * @param _rectangle Rectangle containing the new position and size.
     */
    public function set(_rectangle : Rectangle)
    {
        updateSize(_rectangle.w, _rectangle.h);

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
        updateSize(_width, _height);

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
        switch textures
        {
            case None: //
            case Textures(_textures):
                final width  = _textures[0].width;
                final height = _textures[0].height;

                final uv_x = _normalized ? _uv.x : _uv.x / width;
                final uv_y = _normalized ? _uv.y : _uv.y / height;
                final uv_w = _normalized ? _uv.w : _uv.w / width;
                final uv_h = _normalized ? _uv.h : _uv.h / height;

                updateUVs(uv_x, uv_y, uv_w, uv_h);
        }
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
        switch textures
        {
            case None: //
            case Textures(_textures):
                final width  = _textures[0].width;
                final height = _textures[0].height;

                final uv_x = _normalized ? _x : _x / width;
                final uv_y = _normalized ? _y : _y / height;
                final uv_w = _normalized ? _z : _z / width;
                final uv_h = _normalized ? _w : _w / height;

                updateUVs(uv_x, uv_y, uv_w, uv_h);
        }
    }

    public function setColour(_r : Float, _g : Float, _b : Float, _a : Float)
    {
        switch data
        {
            case Indexed(_vertices, _):
                _vertices.floatAccess[3] = _r;
                _vertices.floatAccess[4] = _g;
                _vertices.floatAccess[5] = _b;
                _vertices.floatAccess[6] = _a;

                _vertices.floatAccess[12] = _r;
                _vertices.floatAccess[13] = _g;
                _vertices.floatAccess[14] = _b;
                _vertices.floatAccess[15] = _a;

                _vertices.floatAccess[21] = _r;
                _vertices.floatAccess[22] = _g;
                _vertices.floatAccess[23] = _b;
                _vertices.floatAccess[24] = _a;

                _vertices.floatAccess[30] = _r;
                _vertices.floatAccess[31] = _g;
                _vertices.floatAccess[32] = _b;
                _vertices.floatAccess[33] = _a;
            case _:
        }
    }

    function updateSize(_w : Float, _h : Float)
    {
        switch data
        {
            case Indexed(_vertices, _):
                _vertices.floatAccess[0] = 0;
                _vertices.floatAccess[1] = _h;

                _vertices.floatAccess[ 9] = _w;
                _vertices.floatAccess[10] = _h;

                _vertices.floatAccess[18] = 0;
                _vertices.floatAccess[19] = 0;

                _vertices.floatAccess[27] = _w;
                _vertices.floatAccess[28] = 0;
            case _:
        }
    }

    function updateUVs(_x : Float, _y : Float, _w : Float, _h : Float)
    {
        switch data
        {
            case Indexed(_vertices, _):
                _vertices.floatAccess[ 7] = _x;
                _vertices.floatAccess[ 8] = _h;

                _vertices.floatAccess[16] = _w;
                _vertices.floatAccess[17] = _h;

                _vertices.floatAccess[25] = _x;
                _vertices.floatAccess[26] = _y;

                _vertices.floatAccess[34] = _w;
                _vertices.floatAccess[35] = _y;
            case _:
        }
    }
}
