package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11Texture2D;
import d3d11.interfaces.D3d11ShaderResourceView;

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

    public function new(_texture, _shaderResourceView)
    {
        texture            = _texture;
        shaderResourceView = _shaderResourceView;
    }
}