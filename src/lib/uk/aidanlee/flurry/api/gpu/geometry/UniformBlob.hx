package uk.aidanlee.flurry.api.gpu.geometry;

import Mat4;
import Vec4;
import haxe.io.BytesOutput;
import haxe.io.Float32Array;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.maths.Hash;

using Safety;
using uk.aidanlee.flurry.api.utils.OutputUtils;

/**
 * Contains a byte buffer which will be copied to the gpu for use in shaders.
 * Has several functions for updating the attributes contained within.
 */
class UniformBlob
{
    /**
     * ID of the uniform blob.
     * This ID is the name hashed.
     */
    public final id : Int;

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
    public function new(_name : String, _buffer : ArrayBufferView)
    {
        id        = Hash.uniqueHash();
        name      = _name;
        buffer    = _buffer;
    }
}

class UniformBlobBuilder
{
    final name : String;

    final writer : BytesOutput;

    final locations : Map<String, Int>;

    var byteOffset : Int;

    public function new(_name : String)
    {
        name       = _name;
        writer     = new BytesOutput();
        locations  = [];
        byteOffset = 0;
    }

    public inline function addMatrix(_name : String, _matrix : Mat4)
    {
        locations[_name] = byteOffset;

        byteOffset += 64;

        writer.writeMatrix(_matrix);

        return this;
    }

    public inline function addVector4(_name : String, _vector : Vec4) : UniformBlobBuilder
    {
        locations[_name] = byteOffset;

        byteOffset += 16;

        writer.writeVector(_vector);

        return this;
    }

    public function uniformBlob() : UniformBlob
    {
        return new UniformBlob(name, ArrayBufferView.fromBytes(writer.getBytes()));
    }
}
