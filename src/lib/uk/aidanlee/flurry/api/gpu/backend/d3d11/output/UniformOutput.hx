package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import Mat4;
import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;

@:nullSafety(Off) class UniformOutput
{
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

    public overload inline extern function write(_v : Vec4)
    {
        floatPointer[floatsWritten + 0] = _v.x;
        floatPointer[floatsWritten + 1] = _v.y;
        floatPointer[floatsWritten + 2] = _v.z;
        floatPointer[floatsWritten + 3] = _v.w;

        floatsWritten += 4;
    }

    public overload inline extern function write(_v : Mat4)
    {
        final data = (_v : Mat4Data);
        floatPointer[floatsWritten +  0] = data.c0.x;
        floatPointer[floatsWritten +  1] = data.c0.y;
        floatPointer[floatsWritten +  2] = data.c0.z;
        floatPointer[floatsWritten +  3] = data.c0.w;
        floatPointer[floatsWritten +  4] = data.c1.x;
        floatPointer[floatsWritten +  5] = data.c1.y;
        floatPointer[floatsWritten +  6] = data.c1.z;
        floatPointer[floatsWritten +  7] = data.c1.w;
        floatPointer[floatsWritten +  8] = data.c2.x;
        floatPointer[floatsWritten +  9] = data.c2.y;
        floatPointer[floatsWritten + 10] = data.c2.z;
        floatPointer[floatsWritten + 11] = data.c2.w;
        floatPointer[floatsWritten + 12] = data.c3.x;
        floatPointer[floatsWritten + 13] = data.c3.y;
        floatPointer[floatsWritten + 14] = data.c3.z;
        floatPointer[floatsWritten + 15] = data.c3.w;

        floatsWritten += 16;
    }
}