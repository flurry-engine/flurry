package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.io.Bytes;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;
import uk.aidanlee.flurry.api.buffers.BufferData;

class IndexBlob
{
    public final buffer : BufferData;

    public final shortAccess : UInt16BufferData;

    public function new(_size : Int)
    {
        final bytes = Bytes.alloc(_size * UInt16BufferData.BYTES_PER_UINT);

        buffer       = new BufferData(bytes, 0, bytes.length);
        shortAccess = buffer;
    }
}

class IndexBlobBuilder
{
    public final indices : IndexBlob;

    var idx : Int;

    public function new(_size : Int)
    {
        indices = new IndexBlob(_size);
        idx     = 0;
    }

    public function addArray(_array : Array<Int>) : IndexBlobBuilder
    {
        for (val in _array)
        {
            indices.shortAccess[idx++] = val;
        }

        return this;
    }
}
