package uk.aidanlee.gpu.batcher;

import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.resources.Resource.ImageResource;
import uk.aidanlee.gpu.geometry.Geometry.BlendMode;
import uk.aidanlee.gpu.geometry.Geometry.PrimitiveType;
import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Matrix;
import snow.api.buffers.Float32Array;

class BufferDrawCommand extends DrawCommand
{
    /**
     * The buffer containing vertex data.
     */
    public final buffer : Float32Array;

    /**
     * The start index for this command.
     */
    public final startIndex : Int;

    /**
     * The end index for this command.
     */
    public final endIndex : Int;

    inline public function new(
        _buffer : Float32Array,
        _startIndex : Int,
        _endIndex : Int,

        _id         : Int,
        _unchanging : Bool,
        _projection : Matrix,
        _view       : Matrix,
        _vertices   : Int,
        _viewport   : Rectangle,
        _primitive  : PrimitiveType,
        _target     : IRenderTarget,
        _shader     : ShaderResource,
        _textures   : Array<ImageResource>,
        _clip       : Rectangle,
        _blending   : Bool,
        _srcRGB     : BlendMode = null,
        _dstRGB     : BlendMode = null,
        _srcAlpha   : BlendMode = null,
        _dstAlpha   : BlendMode = null
    )
    {
        buffer     = _buffer;
        startIndex = _startIndex;
        endIndex   = _endIndex;

        super(_id, _unchanging, _projection, _view, _vertices, _viewport, _primitive, _target, _shader, _textures, _clip, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}