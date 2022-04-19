package uk.aidanlee.flurry.api.gpu.shaders;

import haxe.io.Int32Array;
import haxe.io.Float32Array;
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

    public extern inline overload function write(_offset : Int, _v : Bool)
    {
        final writer = Int32Array.fromData(buffer.getData());

        writer[_offset] = if (_v) 1 else 0;

        return _v;
    }

    public extern inline overload function write(_offset : Int, _v : Int)
    {
        final writer = Int32Array.fromData(buffer.getData());

        writer[_offset] = _v;
    }

    public extern inline overload function write(_offset : Int, _v : Float)
    {
        final writer = Float32Array.fromData(buffer.getData());

        writer[_offset] = _v;
    }

    public extern inline overload function write(_offset : Int, _v : Vec2)
    {
        final writer = Float32Array.fromData(buffer.getData());
        final data   = (cast _v : Vec2.Vec2Data);

        writer[_offset + 0] = data.x;
        writer[_offset + 1] = data.y;

        return _v;
    }

    public extern inline overload function write(_offset : Int, _v : Vec3)
    {
        final writer = Float32Array.fromData(buffer.getData());
        final data   = (cast _v : Vec3.Vec3Data);

        writer[_offset + 0] = data.x;
        writer[_offset + 1] = data.y;
        writer[_offset + 2] = data.z;

        return _v;
    }

    public extern inline overload function write(_offset : Int, _v : Vec4)
    {
        final writer = Float32Array.fromData(buffer.getData());
        final data   = (cast _v : Vec4.Vec4Data);

        writer[_offset + 0] = data.x;
        writer[_offset + 1] = data.y;
        writer[_offset + 2] = data.z;
        writer[_offset + 3] = data.w;

        return _v;
    }

    public extern inline overload function write(_offset : Int, _v : Mat2)
    {
        final data = (cast _v : Mat2.Mat2Data);

        write(_offset + 0, data.c0);
        write(_offset + 4, data.c1);

        return _v;
    }

    public extern inline overload function write(_offset : Int, _v : Mat3)
    {
        final data = (cast _v : Mat3.Mat3Data);

        write(_offset + 0, data.c0);
        write(_offset + 4, data.c1);
        write(_offset + 8, data.c2);

        return _v;
    }

    public extern inline overload function write(_offset : Int, _v : Mat4)
    {
        final data = (cast _v : Mat4.Mat4Data);

        write(_offset +  0, data.c0);
        write(_offset +  4, data.c1);
        write(_offset +  8, data.c2);
        write(_offset + 12, data.c3);

        return _v;
    }
}
