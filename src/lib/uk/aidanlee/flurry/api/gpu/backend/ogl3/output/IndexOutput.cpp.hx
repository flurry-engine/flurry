package uk.aidanlee.flurry.api.gpu.backend.ogl3.output;

import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
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

    public function new(_buffer, _length)
    {
        buffer        = _buffer;
        length        = _length;
        indexOffset   = 0;
        shortPointer  = null;
        shortCursor   = 0;
    }

    /**
     * Reset the base index and indices writen counter as its assumed the index buffer will be rebound
     * with an offset after calling this.
     * @returns index value of the writing cursor position.
     */
    public function reset()
    {
        shortCursor = 0;
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
        final ptr = glMapBufferRange(GL_ELEMENT_ARRAY_BUFFER, 0, length, GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT);

        shortCursor   = 0;
        shortPointer  = (cast ptr : cpp.RawPointer<cpp.UInt16>);
    }

    /**
     * Unmap the buffer.
     */
    public function unmap()
    {
        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
    }

    /**
     * Reset all counters.
     */
    public function close()
    {
        shortCursor = 0;
    }

    public function getIndicesWritten()
    {
        return shortCursor;
    }

    public overload inline extern function write(_v : Int)
    {
        shortPointer[shortCursor] = indexOffset + _v;

        shortCursor++;
    }

    public overload inline extern function write(_v : IndexBlob)
    {
        for (idx in _v.buffer)
        {
            write(idx);
        }
    }
}