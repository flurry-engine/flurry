package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.BlendMode;
import uk.aidanlee.flurry.api.gpu.DepthOptions;
import uk.aidanlee.flurry.api.gpu.StencilOptions;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;

class GeometryDrawCommand extends DrawCommand
{
    /**
     * All of the geometry in this command.
     */
    public final geometry : ReadOnlyArray<Geometry>;

    public inline function new(
        _geometry   : ReadOnlyArray<Geometry>,
        _id         : Int,
        _camera     : Camera,      
        _primitive  : PrimitiveType,
        _clip       : ClipState,
        _target     : TargetState,
        _shader     : ShaderResource,
        _uniforms   : ReadOnlyArray<UniformBlob>,
        _textures   : ReadOnlyArray<ImageResource>,
        _samplers   : ReadOnlyArray<SamplerState>,
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

        super(_id, _camera, _primitive, _clip, _target, _shader, _uniforms, _textures, _samplers, _depth, _stencil, _blending, _srcRGB, _dstRGB, _srcAlpha, _dstAlpha);
    }
}