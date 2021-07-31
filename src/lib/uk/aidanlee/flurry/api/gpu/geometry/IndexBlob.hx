package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.io.BytesOutput;
import haxe.io.UInt16Array;

/**
 * Container class for index bytes data.
 */
class IndexBlob
{
    /**
     * Underlying bytes data.
     */
    public final buffer : UInt16Array;

    public function new(_buffer : UInt16Array)
    {
        buffer = _buffer;
    }
}

/**
 * Helper class which can construct an index blob without having to do all the manual byte management.
 * Contains a series of chainable convenience functions for adding data to an index buffer.
 */
class IndexBlobBuilder
{
    final builder : BytesOutput;

    public function new()
    {
        builder = new BytesOutput();
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
        builder.writeUInt16(_val);

        return this;
    }

    public function indexBlob()
    {
        return new IndexBlob(UInt16Array.fromBytes(builder.getBytes()));
    }
}
