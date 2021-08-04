package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import d3d11.enumerations.D3d11Map;
import haxe.Exception;
import haxe.io.ArrayBufferView;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;
import uk.aidanlee.flurry.api.maths.Maths;

@:nullSafety(Off) class UniformOutput
{
    private static inline var HLSL_CONSTANT_FLOAT_ALIGNMENT = 16 * 4;

    final context : D3d11DeviceContext1;

    final buffer : D3d11Buffer;

    final mapped : D3d11MappedSubResource;

    var floatPointer : cpp.RawPointer<cpp.Float32>;

    var floatCursor : Int;

    var lastUnmapCursor : Int;

    var baseFloatCursor : Int;

    public function new(_context, _buffer)
    {
        context       = _context;
        buffer        = _buffer;
        mapped        = new D3d11MappedSubResource();
        floatPointer  = null;
        floatCursor     = 0;
        lastUnmapCursor = 0;
        baseFloatCursor = 0;
    }

    public function map()
    {
        final flag = if (floatCursor == 0) D3d11Map.WriteDiscard else D3d11Map.WriteNoOverwrite;
        var result = Ok;
        if (Ok != (result = context.map(buffer, 0, flag, 0, mapped)))
        {
            throw new Exception('Failed to map D3D11 vertex buffer : HRESULT $result');
        }

        baseFloatCursor = floatCursor;
        floatPointer    = cast mapped.data.raw;
    }

    public function unmap()
    {
        context.unmap(buffer, 0);

        lastUnmapCursor = floatCursor;
    }

    public function close()
    {
        floatCursor     = 0;
        lastUnmapCursor = 0;
        baseFloatCursor = 0;
    }

    public function getFloatsWritten()
    {
        return floatCursor - lastUnmapCursor;
    }

    public function getBuffer()
    {
        return buffer;
    }
    
    public function write(_buffer : ArrayBufferView)
    {
        final constantPos = cpp.NativeMath.idiv(floatCursor, 4);
        final srcPos      = _buffer.byteOffset;
        final length      = _buffer.byteLength;
        final floats      = cpp.NativeMath.idiv(length, 4);
        final dstPtr      = (mapped.data.reinterpret() : cpp.Pointer<cpp.Float32>).add(floatCursor);
        
        cpp.Native.memcpy(
            dstPtr,
            cpp.NativeArray.address(_buffer.buffer.getData(), srcPos),
            length);

        floatCursor = Maths.nextMultipleOff(floatCursor + floats, HLSL_CONSTANT_FLOAT_ALIGNMENT);

        return constantPos;
    }
}