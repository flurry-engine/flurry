package uk.aidanlee.flurry.api.gpu.backend.ogl3.output;

import opengl.OpenGL.*;

@:nullSafety(Off) class IndexOutput
{
    public final buffer : Int;

    final length : Int;

    /**
     * Value to add to all indicies being written to the buffer.
     */
    var indexOffset : Int;

    /**
     * Pointer to the mapped gpu index buffer.
     */
    var shortPointer : cpp.RawPointer<cpp.UInt16>;

    /**
     * The current writing location into the mapped gpu buffer.
     * This is only reset at the end of the frame so we can do unsynchronised maps.
     */
    var shortCursor : Int;

    /**
     * The total number of indices written into the mapped gpu buffer since the last map.
     */
    var shortsWritten : Int;

    /**
     * The number of indices written into the pointer during the last map.
     * This is reset at a seek as the index buffer is rebound with an offset.
     */
    var baseIndex : Int;

    /**
     * If the next map should be a discard map.
     */
    var discard : Bool;

    public function new(_buffer, _length)
    {
        buffer        = _buffer;
        length        = _length;
        indexOffset   = 0;
        shortPointer  = null;
        shortCursor   = 0;
        shortsWritten = 0;
        baseIndex     = 0;
        discard       = true;
    }

    /**
     * Reset the base index and indices writen counter as its assumed the index buffer will be rebound
     * with an offset after calling this.
     * @returns index value of the writing cursor position.
     */
    public function reset()
    {
        shortsWritten = 0;
        baseIndex     = 0;

        return shortCursor;
    }

    /**
     * Set the index offset value.
     * @param _v New index offset.
     */
    public function offset(_v : Int)
    {
        indexOffset = _v;
    }

    /**
     * Map the buffer for writing. Update the base index to the amount of indices previously written.
     */
    public function map()
    {
        final flag = if (discard) GL_MAP_INVALIDATE_BUFFER_BIT else GL_MAP_UNSYNCHRONIZED_BIT;
        final ptr  = glMapBufferRange(GL_ELEMENT_ARRAY_BUFFER, 0, length, GL_MAP_WRITE_BIT | flag);

        baseIndex     = shortsWritten;
        shortsWritten = 0;
        shortPointer  = (cast ptr : cpp.RawPointer<cpp.UInt16>);
        discard       = false;
    }

    /**
     * Unmap the buffer.
     */
    public function unmap()
    {
        shortsWritten = 0;

        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
    }

    /**
     * Reset all counters.
     */
    public function close()
    {
        shortCursor   = 0;
        shortsWritten = 0;
        baseIndex     = 0;
        discard       = true;
    }

    public function getIndicesWritten()
    {
        return shortsWritten;
    }

    public function getBaseIndex()
    {
        return baseIndex;
    }

    public function write(_v : Int)
    {
        shortPointer[shortCursor] = indexOffset + _v;

        shortCursor++;
        shortsWritten++;
    }
}