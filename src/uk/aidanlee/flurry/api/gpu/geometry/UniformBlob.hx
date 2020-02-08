package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.buffers.BufferData;

class UniformBlob
{
    public final id : Int;

    public final name : String;

    public final buffer : BufferData;

    final locations : Map<String, Int>;

    public function new(_name : String, _bytes : Bytes, _locations : Map<String, Int>)
    {
        id        = Hash.hash(_name);
        name      = _name;
        buffer    = new BufferData(_bytes, 0, _bytes.length);
        locations = _locations;
    }
}

class UniformBlobBuilder
{
    final name : String;

    final writer : BytesBuffer;

    final locations : Map<String, Int>;

    var byteOffset : Int;

    public function new(_name : String)
    {
        name       = _name;
        writer     = new BytesBuffer();
        locations  = [];
        byteOffset = 0;
    }

    public function addMatrix(_name : String, ?_matrix : Matrix) : UniformBlobBuilder
    {
        locations[_name] = byteOffset;

        byteOffset += 64;

        if (_matrix != null)
        {
            final buffer = (cast _matrix : BufferData);

            writer.addBytes(buffer.bytes, buffer.byteOffset, buffer.byteLength);
        }

        return this;
    }

    public function addVector4(_name : String, ?_vector : Vector4) : UniformBlobBuilder
    {
        locations[_name] = byteOffset;

        byteOffset += 16;

        if (_vector != null)
        {
            final buffer = (cast _vector : BufferData);

            writer.addBytes(buffer.bytes, buffer.byteOffset, buffer.byteLength);
        }

        return this;
    }

    public function uniformBlob() : UniformBlob
    {
        return new UniformBlob(name, writer.getBytes(), locations);
    }
}
