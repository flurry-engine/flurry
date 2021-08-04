package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import uk.aidanlee.flurry.api.maths.Maths;
import Mat4;
import haxe.Exception;
import haxe.io.ArrayBufferView;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;

@:nullSafety(Off) class UniformOutput
{
    private static inline var HLSL_CONSTANT_FLOAT_ALIGNMENT = 16 * 4;

    final context : D3d11DeviceContext1;

    final buffer : D3d11Buffer;

    final mapped : D3d11MappedSubResource;

    var floatPointer : cpp.RawPointer<cpp.Float32>;

    var floatsWritten : Int;

    public function new(_context, _buffer)
    {
        context       = _context;
        buffer        = _buffer;
        mapped        = new D3d11MappedSubResource();
        floatPointer  = null;
        floatsWritten = 0;
    }

    public function map()
    {
        var result = Ok;
        if (Ok != (result = context.map(buffer, 0, WriteDiscard, 0, mapped)))
        {
            throw new Exception('Failed to map D3D11 vertex buffer : HRESULT $result');
        }

        floatPointer = cast mapped.data.raw;
    }

    public function unmap()
    {
        context.unmap(buffer, 0);

        floatsWritten = 0;
    }

    public function getFloatsWritten()
    {
        return floatsWritten;
    }

    public function getBuffer()
    {
        return buffer;
    }
    
    public function write(_buffer : ArrayBufferView)
    {
        final constantPos = cpp.NativeMath.idiv(floatsWritten, 4);
        final srcPos      = _buffer.byteOffset;
        final length      = _buffer.byteLength;
        final floats      = cpp.NativeMath.idiv(length, 4);
        final dstPtr      = (mapped.data.reinterpret() : cpp.Pointer<cpp.Float32>).add(floatsWritten);
        
        cpp.Native.memcpy(
            dstPtr,
            cpp.NativeArray.address(_buffer.buffer.getData(), srcPos),
            length);

        floatsWritten = Maths.nextMultipleOff(floatsWritten + floats, HLSL_CONSTANT_FLOAT_ALIGNMENT);

        return constantPos;
    }
}