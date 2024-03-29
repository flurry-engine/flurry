package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.io.BytesOutput;
import haxe.io.Float32Array;

/**
 * Container class for vertex bytes data.
 */
class VertexBlob
{
    /**
     * Underlying bytes data.
     */
    public final buffer : Float32Array;

    public function new(_buffer : Float32Array)
    {
        buffer = _buffer;
    }
}

/**
 * Helper class which can construct a vertex blob without having to do all the manual byte management.
 * Contains a series of chainable convenience functions for adding data to a vertex buffer.
 */
class VertexBlobBuilder
{
    final builder : BytesOutput;

    public function new()
    {
        builder = new BytesOutput();
    }

    public function addFloat(_val : Float) : VertexBlobBuilder
    {
        builder.writeFloat(_val);

        return this;
    }

    public function addFloat2(_val1 : Float, _val2 : Float) : VertexBlobBuilder
    {
        builder.writeFloat(_val1);
        builder.writeFloat(_val2);

        return this;
    }

    public function addFloat3(_val1 : Float, _val2 : Float, _val3 : Float) : VertexBlobBuilder
    {
        builder.writeFloat(_val1);
        builder.writeFloat(_val2);
        builder.writeFloat(_val3);

        return this;
    }

    public function addFloat4(_val1 : Float, _val2 : Float, _val3 : Float, _val4 : Float) : VertexBlobBuilder
    {
        builder.writeFloat(_val1);
        builder.writeFloat(_val2);
        builder.writeFloat(_val3);
        builder.writeFloat(_val4);

        return this;
    }

    public function vertexBlob()
    {
        return new VertexBlob(Float32Array.fromBytes(builder.getBytes()));
    }
}
