package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;
import d3d11.enumerations.D3d11Map;
import uk.aidanlee.flurry.api.maths.Maths;

@:nullSafety(Off) class VertexOutput
{
    public final buffer : D3d11Buffer;

    final context : D3d11DeviceContext1;

    final mapped : D3d11MappedSubResource;

    /**
     * Pointer to the mapped gpu vertex buffer.
     */
    var floatPointer : cpp.RawPointer<cpp.Float32>;

    /**
     * The current writing location into the mapped gpu buffer.
     * This is only reset at the end of the frame so we can do unsynchronised maps.
     */
    var floatCursor : Int;

    /**
     * The total number of floats written into the mapped gpu buffer since the last map.
     */
    var floatsWritten : Int;

    /**
     * The number of vertices written into the pointer during the last map.
     * This is reset at a seek as the vertex buffer is rebound with an offset.
     */
    var baseVertex : Int;

    /**
     * The number of floats in the current vertex input format.
     */
    var floatStride : Int;

    /**
     * If the next map should be a discard map.
     */
    var discard : Bool;

    public function new(_context, _buffer)
    {
        context         = _context;
        buffer          = _buffer;
        mapped          = new D3d11MappedSubResource();
        floatPointer    = null;
        floatCursor     = 0;
        floatsWritten   = 0;
        baseVertex      = 0;
        floatStride     = -1;
        discard         = true;
    }

    /**
     * Seek the vertex buffer write cursor to the next multiple of the supplied stride value.
     * This also resets the floats written and base vertex value as its assumed this is only called
     * when the vertex buffer is rebound with an offset.
     * @param _stride Stride of the new vertex format in bytes.
     * @returns Bytes value of the writing cursor position, aligned to the nearest multiple of the stride.
     */
    public function seek(_stride : Int)
    {
        final bytesCursor = floatCursor * 4;
        final bytesSeek   = nextMultipleOff(bytesCursor, _stride);

        floatCursor   = cpp.NativeMath.idiv(bytesSeek, 4);
        floatStride   = cpp.NativeMath.idiv(_stride, 4);
        floatsWritten = 0;
        baseVertex    = 0;

        return bytesSeek;
    }

    /**
     * Map the buffer for writing. Update the base vertex to the amount of verticies previously written.
     */
    public function map()
    {
        final flag  = if (discard) D3d11Map.WriteDiscard else D3d11Map.WriteNoOverwrite;
        var result  = Ok;
        if (Ok != (result = context.map(buffer, 0, flag, 0, mapped)))
        {
            throw new Exception('Failed to map D3D11 vertex buffer : HRESULT $result');
        }

        baseVertex    = cpp.NativeMath.idiv(floatsWritten, floatStride);
        floatsWritten = 0;
        floatPointer  = cast mapped.data.raw;
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
        floatCursor   = 0;
        floatsWritten = 0;
        baseVertex    = 0;
        discard       = true;
        floatStride   = -1;
    }

    public function getVerticesWritten()
    {
        return cpp.NativeMath.idiv(floatsWritten, floatStride);
    }

    public function getBaseVertex()
    {
        return baseVertex;
    }

    public overload inline extern function write(_v : Float)
    {
        floatPointer[floatCursor] = _v;

        floatCursor++;
        floatsWritten++;
    }

    public overload inline extern function write(_v : Vec2)
    {
        floatPointer[floatCursor + 0] = _v.x;
        floatPointer[floatCursor + 1] = _v.y;

        floatCursor += 2;
        floatsWritten += 2;
    }

    public overload inline extern function write(_v : Vec3)
    {
        floatPointer[floatCursor + 0] = _v.x;
        floatPointer[floatCursor + 1] = _v.y;
        floatPointer[floatCursor + 2] = _v.z;

        floatCursor += 3;
        floatsWritten += 3;
    }

    public overload inline extern function write(_v : Vec4)
    {
        floatPointer[floatCursor + 0] = _v.x;
        floatPointer[floatCursor + 1] = _v.y;
        floatPointer[floatCursor + 2] = _v.z;
        floatPointer[floatCursor + 3] = _v.w;

        floatCursor += 4;
        floatsWritten += 4;
    }
}