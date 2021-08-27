package uk.aidanlee.flurry.api.gpu.shaders;

import haxe.io.ArrayBufferView;

/**
 * Contains a byte buffer which will be copied to the gpu for use in shaders.
 * Has several functions for updating the attributes contained within.
 */
class UniformBlob
{
    /**
     * The name of the uniform blob.
     * This name should match to a buffer found in the shader.
     */
    public final name : String;

    /**
     * Buffer bytes data.
     */
    public final buffer : ArrayBufferView;

    /**
     * Create a new uniform blob.
     * @param _name Name of the blob.
     * @param _buffer Buffer bytes.
     * @param _locations Locations of all the attributes in the buffer.
     */
    public function new(_name, _buffer)
    {
        name   = _name;
        buffer = _buffer;
    }
}
