package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;

/**
 * A draw command describes how to draw a set amount of data within a vertex buffer.
 * These commands contain the buffer range, shader, texture, viewport, etc.
 */
class DrawCommand
{
    /**
     * All of the geometry in this command.
     */
    public final geometry : ReadOnlyArray<Geometry>;

    /**
     * Projection matrix to draw this command with.
     */
    public final camera : Camera;

    /**
     * Primitive type of this draw command.
     */
    public final primitive : PrimitiveType;

    /**
     * The clipping rectangle for this draw command.
     */
    public final clip : ClipState;

    /**
     * The render target for this draw command.
     */
    public final target : TargetState;

    /**
     * Shader to be used to draw this data.
     */
    public final shader : ShaderResource;

    /**
     * If provided uniform values are fetch from here before the shader defaults.
     */
    public final uniforms : ReadOnlyArray<UniformBlob>;

    /**
     * Textures to be used with this draw command.
     */
    public final textures : ReadOnlyArray<ImageFrameResource>;

    /**
     * Samples to be used with this draw command.
     * 
     * Less samplers than textures can be provided. Backends will use a default sampler when one is not explicitly provided.
     */
    public final samplers : ReadOnlyArray<SamplerState>;

    /**
     * Depth testing options for this draw command.
     */
    public final depth : DepthState;

    /**
     * Stencil testing options for this draw command.
     */
    public final stencil : StencilState;

    /**
     * Blending options for this draw command.
     */
    public final blending : BlendState;

    inline public function new(
        _geometry   : ReadOnlyArray<Geometry>,
        _camera     : Camera,
        _primitive  : PrimitiveType,
        _clip       : ClipState,
        _target     : TargetState,
        _shader     : ShaderResource,
        _uniforms   : ReadOnlyArray<UniformBlob>,
        _textures   : ReadOnlyArray<ImageFrameResource>,
        _samplers   : ReadOnlyArray<SamplerState>,
        _depth      : DepthState,
        _stencil    : StencilState,
        _blending   : BlendState)
    {
        geometry   = _geometry;
        camera     = _camera;
        primitive  = _primitive;
        clip       = _clip;
        target     = _target;
        shader     = _shader;
        uniforms   = _uniforms;
        textures   = _textures;
        samplers   = _samplers;
        depth      = _depth;
        stencil    = _stencil;
        blending   = _blending;
    }
}
