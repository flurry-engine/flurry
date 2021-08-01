package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11Texture2D;
import d3d11.interfaces.D3d11SamplerState;
import d3d11.interfaces.D3d11RenderTargetView;
import d3d11.interfaces.D3d11ShaderResourceView;
import d3d11.structures.D3d11Texture2DDescription;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;

using Safety;

/**
 * Holds the DirectX resources required for drawing a texture.
 */
class D3D11TextureInformation
{
    /**
     * D3D11 Texture2D pointer.
     */
    public final texture : D3d11Texture2D;

    /**
     * D3D11 Shader Resource View to view the texture.
     */
    public final shaderResourceView : D3d11ShaderResourceView;

    /**
     * D3D11 Render Target View to draw to the texture.
     */
    public final renderTargetView : D3d11RenderTargetView;

    /**
     * D3D11 Texture 2D description, contains info on the underlying texture data.
     */
    public final description : D3d11Texture2DDescription;

    /**
     * D3D11 Sampler State to sample the textures data.
     */
    public final samplers : Map<SamplerState, D3d11SamplerState>;

    public function new(_texture, _resView, _rtvView, _description)
    {
        texture            = _texture;
        shaderResourceView = _resView;
        renderTargetView   = _rtvView;
        description        = _description;
        samplers           = [];
    }

    public function destroy()
    {
        texture.release();
        shaderResourceView.release();
        renderTargetView.release();

        for (sampler in samplers)
        {
            sampler.release();
        }
    }
}