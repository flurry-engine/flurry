package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.io.BytesBuffer;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.buffers.BufferData;

class VertexBlob
{
    public final buffer : BufferData;

    public final floatAccess : Float32BufferData;

    public function new(_buffer : BufferData)
    {
        buffer      = _buffer;
        floatAccess = _buffer;
    }
}

class VertexBlobBuilder
{
    final builder : BytesBuffer;

    public function new()
    {
        builder = new BytesBuffer();
    }

    public function addVector2(_vec : Vector2) : VertexBlobBuilder
    {
        builder.addFloat(_vec.x);
        builder.addFloat(_vec.y);

        return this;
    }

    public function addVector3(_vec : Vector3) : VertexBlobBuilder
    {
        builder.addFloat(_vec.x);
        builder.addFloat(_vec.y);
        builder.addFloat(_vec.z);

        return this;
    }

    public function addVector4(_vec : Vector4) : VertexBlobBuilder
    {
        builder.addFloat(_vec.x);
        builder.addFloat(_vec.y);
        builder.addFloat(_vec.z);
        builder.addFloat(_vec.w);

        return this;
    }

    public function addVertex(_pos : Vector3, _col : Vector4, _tex : Vector2) : VertexBlobBuilder
    {
        addVector3(_pos);
        addVector4(_col);
        addVector2(_tex);

        return this;
    }

    public function addArray(_array : Array<Float>) : VertexBlobBuilder
    {
        for (v in _array)
        {
            builder.addFloat(v);
        }

        return this;
    }

    public function vertexBlob()
    {
        final bytes = builder.getBytes();

        return new VertexBlob(new BufferData(bytes, 0, bytes.length));
    }
}
