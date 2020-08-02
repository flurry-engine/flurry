package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.buffers.BufferData;
import uk.aidanlee.flurry.api.buffers.GrowingBuffer;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;

/**
 * Container class for index bytes data.
 */
class IndexBlob
{
    /**
     * Underlying bytes data.
     */
    public final buffer : BufferData;

    /**
     * Quick access to the underlying bytes data as a typed ushort buffer.
     */
    public final shortAccess : UInt16BufferData;

    public function new(_buffer : BufferData)
    {
        buffer      = _buffer;
        shortAccess = _buffer;
    }
}

/**
 * Helper class which can construct an index blob without having to do all the manual byte management.
 * Contains a series of chainable convenience functions for adding data to an index buffer.
 */
class IndexBlobBuilder
{
    final builder : GrowingBuffer;

    public function new()
    {
        builder = new GrowingBuffer();
    }

    public function addInts(_array : Array<Int>) : IndexBlobBuilder
    {
        for (val in _array)
        {
            addInt(val);
        }

        return this;
    }

    public function addInt(_val : Int) : IndexBlobBuilder
    {
        builder.addUInt16(_val);

        return this;
    }

    public function indexBlob()
    {
        final bytes = builder.getBytes();

        return new IndexBlob(new BufferData(bytes, 0, bytes.length));
    }
}
