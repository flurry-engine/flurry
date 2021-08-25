package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11BlendState;
import d3d11.interfaces.D3d11DepthStencilState;
import d3d11.enumerations.D3d11PrimitiveTopology;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;

class D3D11PipelineState
{
    public final shader : ShaderID;

    public final surface : SurfaceID;

    public final depthStencilState : D3d11DepthStencilState;

    public final blendState : D3d11BlendState;

    public final primitive : D3d11PrimitiveTopology;

    public function new(_shader, _surface, _depthStencilState, _blendState, _primitive)
    {
        shader            = _shader;
        surface           = _surface;
        depthStencilState = _depthStencilState;
        blendState        = _blendState;
        primitive         = _primitive;
    }
}