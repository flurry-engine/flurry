package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.io.BytesBuffer;
import uk.aidanlee.flurry.api.buffers.BufferData;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;

class IndexBlob
{
    public final buffer : BufferData;

    public final shortAccess : UInt16BufferData;

    public function new(_buffer : BufferData)
    {
        buffer      = _buffer;
        shortAccess = _buffer;
    }
}

class IndexBlobBuilder
{
    final builder : BytesBuffer;

    public function new()
    {
        builder = new BytesBuffer();
    }

    public function addArray(_array : Array<Int>) : IndexBlobBuilder
    {
        for (val in _array)
        {
            addInt(val);
        }

        return this;
    }

    public function addInt(_val : Int) : IndexBlobBuilder
    {
        builder.addByte(_val & 0xff);
        builder.addByte(_val >> 8);

        return this;
    }

    public function indexBlob()
    {
        final bytes = builder.getBytes();

        return new IndexBlob(new BufferData(bytes, 0, bytes.length));
    }
}
