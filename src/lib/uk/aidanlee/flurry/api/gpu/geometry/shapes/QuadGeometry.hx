package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob.IndexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;

using Safety;

typedef QuadGeometryOptions = {
    var texture : ImageFrameResource;
    var ?sampler : SamplerState;
    var ?shader : GeometryShader;
    var ?uniforms : GeometryUniforms;
    var ?depth : Float;
    var ?clip : ClipState;
    var ?blend : BlendState;
    var ?batchers : Array<Batcher>;
    var ?x : Float;
    var ?y : Float;
    var ?width : Float;
    var ?height : Float;
}

class QuadGeometry extends Geometry
{
    public function new(_options : QuadGeometryOptions)
    {
        final u1     = _options.texture.u1;
        final v1     = _options.texture.v1;
        final u2     = _options.texture.u2;
        final v2     = _options.texture.v2;
        final width  = _options.width.or(_options.texture.width);
        final height = _options.height.or(_options.texture.height);

        super({
            data : Indexed(
                new VertexBlobBuilder()
                    .addFloat3(    0, height, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v2)
                    .addFloat3(width, height, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v2)
                    .addFloat3(    0,      0, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v1)
                    .addFloat3(width,      0, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v1)
                    .vertexBlob(),
                new IndexBlobBuilder()
                    .addInt(0).addInt(1).addInt(2).addInt(2).addInt(1).addInt(3)
                    .indexBlob()
            ),
            textures : Textures([ _options.texture ]),
            samplers : _options.sampler == null ? None : Samplers([ _options.sampler ]),
            shader   : _options.shader,
            uniforms : _options.uniforms,
            depth    : _options.depth,
            clip     : _options.clip,
            blend    : _options.blend,
            batchers : _options.batchers
        });

        position.set_xy(_options.x.or(0), _options.y.or(0));
    }

    /**
     * Resize the quad according to two floats.
     * @param _x New width of the quad.
     * @param _y New height of the quad.
     */
    public function resize(_x : Float, _y : Float)
    {
        updateSize(_x, _y);
    }

    /**
     * Set the position and size of the quad from four floats.
     * @param _x New x position of the quad.
     * @param _y New y position of the quad.
     * @param _w New width of the quad.
     * @param _h New height of the quad.
     */
    public function set(_x : Float, _y : Float, _width : Float, _height : Float)
    {
        updateSize(_width, _height);

        transformation.position.set_xy(_x, _y);
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
    public function uv(_x : Float, _y : Float, _z : Float, _w : Float, _normalized : Bool = true)
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

    /**
     * Updates this geometry to display the provided frame.
     * @param _frame Frame to display.
     */
    public function reframe(_frame : ImageFrameResource)
    {
        final replace = switch textures
        {
            case None: true;
            case Textures(_frames): _frames.length < 1 || _frames[0].id != _frame.id;
        }

        if (replace)
        {
            textures = Textures([ _frame ]);
        }

        updateSize(_frame.width, _frame.height);
        updateUVs(_frame.u1, _frame.v1, _frame.u2, _frame.v2);
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
