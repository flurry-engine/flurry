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
     * Stores the byte offset of each attribute in the buffer based on attribute name.
     * 
     * Will eventually be useful for dealing with shader block alignment.
     */
    final locations : Map<String, Int>;

    /**
     * Create a new uniform blob.
     * @param _name Name of the blob.
     * @param _buffer Buffer bytes.
     * @param _locations Locations of all the attributes in the buffer.
     */
    public function new(_name : String, _buffer : ArrayBufferView, _locations : Map<String, Int>)
    {
        id        = Hash.uniqueHash();
        name      = _name;
        buffer    = _buffer;
        locations = _locations;
    }

    /**
     * Copies a matrix into the uniform buffer.
     * @param _name Attribute name.
     * @param _matrix Matrix object to copy.
     */
    public inline function setMatrix(_name : String, _matrix : Mat4)
    {
        if (locations.exists(_name))
        {
            final pos    = Std.int(buffer.byteOffset + locations[_name].unsafe() / 4);
            final access = Float32Array.fromData(cast buffer);
            final data   = (_matrix : Mat4Data);

            access[pos +  0] = data.c0.x;
            access[pos +  1] = data.c0.y;
            access[pos +  2] = data.c0.z;
            access[pos +  3] = data.c0.w;
            access[pos +  4] = data.c1.x;
            access[pos +  5] = data.c1.y;
            access[pos +  6] = data.c1.z;
            access[pos +  7] = data.c1.w;
            access[pos +  8] = data.c2.x;
            access[pos +  9] = data.c2.y;
            access[pos + 10] = data.c2.z;
            access[pos + 11] = data.c2.w;
            access[pos + 12] = data.c3.x;
            access[pos + 13] = data.c3.y;
            access[pos + 14] = data.c3.z;
            access[pos + 15] = data.c3.w;
        }
    }

    /**
     * Copies a vector into the uniform buffer.
     * @param _name Attribute name.
     * @param _vector Vector object to copy.
     */
    public inline function setVector4(_name : String, _vector : Vec4)
    {
        if (locations.exists(_name))
        {
            final pos    = Std.int(buffer.byteOffset + locations[_name].unsafe() / 4);
            final access = Float32Array.fromData(cast buffer);
            final data   = (_vector : Vec4Data);

            access[pos +  0] = data.x;
            access[pos +  1] = data.y;
            access[pos +  2] = data.z;
            access[pos +  3] = data.w;
        }
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
        return new UniformBlob(name, ArrayBufferView.fromBytes(writer.getBytes()), locations);
    }
}
