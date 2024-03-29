package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;
import d3d11.enumerations.D3d11Map;
import uk.aidanlee.flurry.api.maths.Maths;

@:nullSafety(Off) class IndexOutput
{
    public final buffer : D3d11Buffer;

    final context : D3d11DeviceContext1;

    final mapped : D3d11MappedSubResource;

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

    public function new(_context, _buffer)
    {
        context       = _context;
        buffer        = _buffer;
        mapped        = new D3d11MappedSubResource();
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
     * @returns Bytes value of the writing cursor position.
     */
    public function reset()
    {
        shortsWritten = 0;
        baseIndex     = 0;

        return shortCursor * 2;
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
        final flag = if (discard) D3d11Map.WriteDiscard else D3d11Map.WriteNoOverwrite;
        var result = Ok;
        if (Ok != (result = context.map(buffer, 0, flag, 0, mapped)))
        {
            throw new Exception('Failed to map D3D11 index buffer : HRESULT $result');
        }

        baseIndex    += shortsWritten;
        shortsWritten = 0;
        shortPointer  = cast mapped.data.raw;
        discard       = false;
    }

    /**
     * Unmap the buffer.
     */
    public function unmap()
    {
        context.unmap(buffer, 0);
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

    public overload inline extern function write(_v : Int)
    {
        shortPointer[shortCursor] = indexOffset + _v;

        shortCursor++;
        shortsWritten++;
    }

    public overload inline extern function write(_v : IndexBlob)
    {
        for (idx in _v.buffer)
        {
            write(idx);
        }
    }
}