package uk.aidanlee.flurry.api.gpu.batcher;

import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Matrix;
import haxe.io.Float32Array;

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
        _indices    : Int,
        _viewport   : Rectangle,
        _primitive  : PrimitiveType,
        _target     : ImageResource,
        _shader     : ShaderResource,
        _uniforms   : Null<Uniforms>,
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

        super(_id, _unchanging, _projection, _view, _vertices, _indices, _viewport, _primitive, _target, _shader, _uniforms, _textures, _clip, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}