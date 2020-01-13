package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Vector2;
import haxe.io.Bytes;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.buffers.BufferData;

class VertexBlob
{
    public final buffer : BufferData;

    public final floatAccess : Float32BufferData;

    public function new(_size : Int)
    {
        final bytes = Bytes.alloc(_size * Float32BufferData.BYTES_PER_FLOAT);

        buffer      = new BufferData(bytes, 0, bytes.length);
        floatAccess = buffer;
    }
}

class VertexBlobBuilder
{
    public final vertices : VertexBlob;

    var idx : Int;

    public function new(_size : Int)
    {
        vertices = new VertexBlob(_size);
        idx      = 0;
    }

    public function addVector2(_vec : Vector2) : VertexBlobBuilder
    {
        vertices.floatAccess[idx++] = _vec.x;
        vertices.floatAccess[idx++] = _vec.y;

        return this;
    }

    public function addVector3(_vec : Vector3) : VertexBlobBuilder
    {
        vertices.floatAccess[idx++] = _vec.x;
        vertices.floatAccess[idx++] = _vec.y;
        vertices.floatAccess[idx++] = _vec.z;

        return this;
    }

    public function addVector4(_vec : Vector4) : VertexBlobBuilder
    {
        vertices.floatAccess[idx++] = _vec.x;
        vertices.floatAccess[idx++] = _vec.y;
        vertices.floatAccess[idx++] = _vec.z;
        vertices.floatAccess[idx++] = _vec.w;

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
            vertices.floatAccess[idx++] = v;
        }

        return this;
    }
}
