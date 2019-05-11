package uk.aidanlee.flurry.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.batcher.Batcher.StencilOptions;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher.DepthOptions;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;

class GeometryDrawCommand extends DrawCommand
{
    /**
     * All of the geometry in this command.
     */
    public final geometry : Array<Geometry>;

    public inline function new(
        _geometry   : Array<Geometry>,
        _id         : Int,
        _uploadType : UploadType,
        _projection : Matrix,
        _view       : Matrix,
        _vertices   : Int,
        _indices    : Int,
        _viewport   : Rectangle,
        _primitive  : PrimitiveType,
        _target     : ImageResource,
        _shader     : ShaderResource,
        _uniforms   : Uniforms,
        _textures   : Array<ImageResource>,
        _clip       : Rectangle,
        _depth      : DepthOptions,
        _stencil    : StencilOptions,
        _blending   : Bool,
        _srcRGB     : BlendMode = null,
        _dstRGB     : BlendMode = null,
        _srcAlpha   : BlendMode = null,
        _dstAlpha   : BlendMode = null
    )
    {
        geometry = _geometry;

        super(_id, _uploadType, _projection, _view, _vertices, _indices, _viewport, _primitive, _target, _shader, _uniforms, _textures, _clip, _depth, _stencil, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}