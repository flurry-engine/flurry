package uk.aidanlee.flurry.api.buffers;

import haxe.io.Bytes;
import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.maths.Maths;

/**
 * This buffer grows by doubling its size each time it needs to be re-allocated.
 * Mainly used for the vertex and index buffer builder so there aren't many input function outside of floats and uint16s.
 */
class GrowingBuffer
{
    var bytes : Bytes;

    var index : Int;

    var capacity : Int;

    public function new()
    {
        bytes    = Bytes.alloc(4);
        capacity = bytes.length;
        index    = 0;
    }

    public function addFloat(_val)
    {
        if (index + 4 > capacity)
        {
            realloc(capacity + 4);
        }

        bytes.setFloat(index, _val);

        index += 4;

        return this;
    }

    public function addFloat2(_val1, _val2)
    {
        if (index + 8 > capacity)
        {
            realloc(capacity + 8);
        }

        bytes.setFloat(index + 0, _val1);
        bytes.setFloat(index + 4, _val2);

        index += 8;

        return this;
    }

    public function addFloat3(_val1, _val2, _val3)
    {
        if (index + 12 > capacity)
        {
            realloc(capacity + 12);
        }

        bytes.setFloat(index + 0, _val1);
        bytes.setFloat(index + 4, _val2);
        bytes.setFloat(index + 8, _val3);

        index += 12;

        return this;
    }

    public function addFloat4(_val1, _val2, _val3, _val4)
    {
        if (index + 16 > capacity)
        {
            realloc(capacity + 16);
        }

        bytes.setFloat(index +  0, _val1);
        bytes.setFloat(index +  4, _val2);
        bytes.setFloat(index +  8, _val3);
        bytes.setFloat(index + 12, _val4);

        index += 16;

        return this;
    }

    public function addUInt16(_val)
    {
        if (index + 2 > capacity)
        {
            realloc(capacity + 2);
        }

        bytes.setUInt16(index, _val);

        index += 2;

        return this;
    }

    public function addUInt16s(_vals : ReadOnlyArray<Int>)
    {
        for (val in _vals)
        {
            if (index + 2 > capacity)
            {
                realloc(capacity + 2);
            }

            bytes.setUInt16(index, val);

            index += 2;
        }

        return this;
    }

    /**
     * Return a bytes object of whats been written to the buffer so far.
     */
    public function getBytes()
    {
        return bytes.sub(0, index);
    }

    /**
     * Reset the current writing position in this buffer.
     */
    public function reset()
    {
        index = 0;
    }

    /**
     * Reallocate the underlying bytes object.
     * Will resize to either double the current capacity or to provided size, which ever is larger.
     * @param _ensure Minimum size to re-allocate the buffer to.
     */
    function realloc(_ensure)
    {
        final newCapacity = Std.int(Maths.max(_ensure, capacity * 2));
        final newBytes    = Bytes.alloc(newCapacity);

        newBytes.blit(0, bytes, 0, capacity);

        bytes    = newBytes;
        capacity = newCapacity;
    }
}