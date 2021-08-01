package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;

@:nullSafety(Off) class VertexOutput
{
    static inline var VERTEX_STRIDE = 9;

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

    public function getVerticesWritten()
    {
        return cpp.NativeMath.idiv(floatsWritten, VERTEX_STRIDE);
    }

    public overload inline extern function write(_v : Float)
    {
        floatPointer[floatsWritten] = _v;

        floatsWritten++;
    }

    public overload inline extern function write(_v : Vec2)
    {
        floatPointer[floatsWritten + 0] = _v.x;
        floatPointer[floatsWritten + 1] = _v.y;

        floatsWritten += 2;
    }

    public overload inline extern function write(_v : Vec3)
    {
        floatPointer[floatsWritten + 0] = _v.x;
        floatPointer[floatsWritten + 1] = _v.y;
        floatPointer[floatsWritten + 2] = _v.z;

        floatsWritten += 3;
    }

    public overload inline extern function write(_v : Vec4)
    {
        floatPointer[floatsWritten + 0] = _v.x;
        floatPointer[floatsWritten + 1] = _v.y;
        floatPointer[floatsWritten + 2] = _v.z;
        floatPointer[floatsWritten + 3] = _v.w;

        floatsWritten += 4;
    }
}