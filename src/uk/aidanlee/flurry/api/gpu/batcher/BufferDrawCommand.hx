package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.io.Float32Array;
import haxe.io.UInt16Array;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Matrix;

class BufferDrawCommand extends DrawCommand
{
    /**
     * The buffer containing vertex data.
     */
    public final vtxData : Float32Array;

    /**
     * The start index for this command.
     */
    public final vtxStartIndex : Int;

    /**
     * The end index for this command.
     */
    public final vtxEndIndex : Int;

    public final idxData : UInt16Array;

    public final idxStartIndex : Int;

    public final idxEndIndex : Int;

    inline public function new(
        _vtxData       : Float32Array,
        _vtxStartIndex : Int,
        _vtxEndIndex   : Int,
        _idxData       : UInt16Array,
        _idxStartIndex : Int,
        _idxEndIndex   : Int,

        _id         : Int,
        _uploadType : UploadType,
        _projection : Matrix,
        _view       : Matrix,
        _viewport   : Rectangle,
        _primitive  : PrimitiveType,
        _target     : ImageResource,
        _shader     : ShaderResource,
        _uniforms   : Uniforms,
        _textures   : Array<ImageResource>,
        _clip       : Rectangle,
        _blending   : Bool,
        _srcRGB     : BlendMode = null,
        _dstRGB     : BlendMode = null,
        _srcAlpha   : BlendMode = null,
        _dstAlpha   : BlendMode = null
    )
    {
        vtxData       = _vtxData;
        vtxStartIndex = _vtxStartIndex;
        vtxEndIndex   = _vtxEndIndex;
        idxData       = _idxData;
        idxStartIndex = _idxStartIndex;
        idxEndIndex   = _idxEndIndex;

        super(_id, _uploadType, _projection, _view, vtxEndIndex - vtxStartIndex, idxEndIndex - idxStartIndex, _viewport, _primitive, _target, _shader, _uniforms, _textures, _clip, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}