package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11Texture2D;
import d3d11.interfaces.D3d11DepthStencilView;
import d3d11.interfaces.D3d11RenderTargetView;
import d3d11.interfaces.D3d11ShaderResourceView;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceState;

class D3D11SurfaceInformation
{
    public final state : SurfaceState;

    public final surfaceTexture : D3d11Texture2D;

    public final surfaceView : D3d11ShaderResourceView;

    public final surfaceRenderView : D3d11RenderTargetView;

    public final depthStencilTexture : D3d11Texture2D;

    public final depthStencilView : D3d11DepthStencilView;

    public function new(_state, _texture, _resource, _target, _dsTexture, _dsView)
    {
        state               = _state;
        surfaceTexture      = _texture;
        surfaceView         = _resource;
        surfaceRenderView   = _target;
        depthStencilTexture = _dsTexture;
        depthStencilView    = _dsView;
    }
}