package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11Texture2D;
import d3d11.interfaces.D3d11DepthStencilView;
import d3d11.interfaces.D3d11RenderTargetView;
import d3d11.interfaces.D3d11ShaderResourceView;

class D3D11SurfaceInformation
{
    public final surfaceTexture : D3d11Texture2D;

    public final surfaceView : D3d11ShaderResourceView;

    public final surfaceRenderView : D3d11RenderTargetView;

    public final depthStencilTexture : D3d11Texture2D;

    public final depthStencilView : D3d11DepthStencilView;

    public function new(_surfaceTexture, _surfaceView, _surfaceRenderView, _depthStencilTexture, _depthStencilView)
    {
        surfaceTexture      = _surfaceTexture;
        surfaceView         = _surfaceView;
        surfaceRenderView   = _surfaceRenderView;
        depthStencilTexture = _depthStencilTexture;
        depthStencilView    = _depthStencilView;
    }
}