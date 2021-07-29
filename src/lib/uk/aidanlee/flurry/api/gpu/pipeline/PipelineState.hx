package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;

@:publicFields @:structInit class PipelineState
{
    final shader : ShaderID;

    final target = TargetID.backbuffer;

    final depth = DepthState.none;

    final stencil = StencilState.none;

    final blend = BlendState.none;

    final primitive = PrimitiveType.Triangles;
}