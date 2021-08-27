package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11InputLayout;
import d3d11.interfaces.D3d11PixelShader;
import d3d11.interfaces.D3d11VertexShader;
import haxe.ds.Vector;

/**
 * Holds the DirectX resources required for setting and uploading data to a shader.
 */
class D3D11ShaderInformation
{
    /**
     * Names of all cbuffers in the vertex stage.
     */
    public final vertBlocks : Vector<String>;

    /**
     * Names of all cbuffers in the fragment stage.
     */
    public final fragBlocks : Vector<String>;

    /**
     * Number of textures / samplers used in the fragment stage.
     */
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

    /**
     * Number of bytes between each element in this shaders vertex input.
     */
    public final inputStride : Int;

    public function new(_vertBlocks, _fragBlocks, _textures, _vertex, _pixel, _inputLayout, _inputStride)
    {
        vertBlocks   = _vertBlocks;
        fragBlocks   = _fragBlocks;
        textures     = _textures;
        vertexShader = _vertex;
        pixelShader  = _pixel;
        inputLayout  = _inputLayout;
        inputStride  = _inputStride;
    }

    /**
     * Find the location of a cbuffer in the vertex stage given its name.
     * @param _name Name of the cbuffer.
     * @returns Location of the cbuffer, or -1 if it was not found.
     */
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
}