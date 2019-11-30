package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.io.Float32Array;
import haxe.io.UInt16Array;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.BlendMode;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.StencilOptions;
import uk.aidanlee.flurry.api.gpu.DepthOptions;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Rectangle;

class BufferDrawCommand extends DrawCommand
{
    /**
     * The buffer containing vertex data.
     */
    public final vtxData : Float32Array;

    /**
     * The start location for the vertex data.
     */
    public final vtxStartIndex : Int;

    /**
     * The end location ffor the vertex data.
     */
    public final vtxEndIndex : Int;

    /**
     * The buffer containing index data.
     */
    public final idxData : UInt16Array;

    /**
     * The start location for the index data.
     */
    public final idxStartIndex : Int;

    /**
     * The end location for the index data.
     */
    public final idxEndIndex : Int;

    /**
     * Model matrix used to transform the vertex data.
     */
    public final model : Matrix;

    inline public function new(
        _vtxData       : Float32Array,
        _vtxStartIndex : Int,
        _vtxEndIndex   : Int,
        _idxData       : UInt16Array,
        _idxStartIndex : Int,
        _idxEndIndex   : Int,
        _model         : Matrix,

        _id         : Int,
        _uploadType : UploadType,
        _camera     : Camera,
        _clip       : Null<Rectangle>,
        _primitive  : PrimitiveType,
        _target     : ImageResource,
        _shader     : ShaderResource,
        _uniforms   : Uniforms,
        _textures   : Array<ImageResource>,
        _samplers   : Array<Null<SamplerState>>,
        _depth      : DepthOptions,
        _stencil    : StencilOptions,
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
        model         = _model;

        super(_id, _uploadType, _camera, clip, vtxEndIndex - vtxStartIndex, idxEndIndex - idxStartIndex, _primitive, _target, _shader, _uniforms, _textures, _samplers, _depth, _stencil, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}