package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import haxe.Exception;
import d3d11.interfaces.D3d11InputLayout;
import d3d11.interfaces.D3d11PixelShader;
import d3d11.interfaces.D3d11VertexShader;
import haxe.ds.Vector;

/**
 * Holds the DirectX resources required for setting and uploading data to a shader.
 */
class D3D11ShaderInformation
{
    public final vertBlocks : Vector<String>;

    public final fragBlocks : Vector<String>;

    public final textures : Int;

    /**
     * D3D11 vertex shader pointer.
     */
    public final vertexShader : D3d11VertexShader;

    /**
     * D3D11 pixel shader pointer.
     */
    public final pixelShader : D3d11PixelShader;

    /**
     * D3D11 Vertex input description of this shader.
     */
    public final inputLayout : D3d11InputLayout;

    public function new(_vertBlocks, _fragBlocks, _textures, _vertex, _pixel, _input)
    {
        vertBlocks   = _vertBlocks;
        fragBlocks   = _fragBlocks;
        textures     = _textures;
        vertexShader = _vertex;
        pixelShader  = _pixel;
        inputLayout  = _input;
    }

    public function findVertexBlockLocation(_name : String)
    {
        for (i in 0...vertBlocks.length)
        {
            if (vertBlocks[i] == _name)
            {
                return i;
            }
        }

        return -1;
    }

    public function destroy()
    {
        vertexShader.release();
        pixelShader.release();
        inputLayout.release();
    }
}