package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.gpu.shaders.ShaderID;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;

@:publicFields @:structInit class PipelineState
{
    final shader : ShaderID;

    final surface = SurfaceID.backbuffer;

    final depth = DepthState.none;

    final stencil = StencilState.none;

    final blend = BlendState.none;

    final primitive = PrimitiveType.Triangles;
}