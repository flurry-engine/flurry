package uk.aidanlee.flurry.api.gpu.pipeline;

@:publicFields @:structInit class PipelineState
{
    final shader : ShaderID;

    final surface = SurfaceID.backbuffer;

    final depth = DepthState.none;

    final stencil = StencilState.none;

    final blend = BlendState.none;

    final primitive = PrimitiveType.Triangles;
}