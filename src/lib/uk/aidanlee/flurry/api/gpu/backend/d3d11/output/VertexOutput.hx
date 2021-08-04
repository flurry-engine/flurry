package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;
import d3d11.enumerations.D3d11Map;

@:nullSafety(Off) class VertexOutput
{
    static inline var VERTEX_STRIDE = 9;

    final context : D3d11DeviceContext1;

    final buffer : D3d11Buffer;

    final mapped : D3d11MappedSubResource;

    var floatPointer : cpp.RawPointer<cpp.Float32>;

    var floatCursor : Int;

    var lastUnmapCursor : Int;

    var baseFloatCursor : Int;

    public function new(_context, _buffer)
    {
        context         = _context;
        buffer          = _buffer;
        mapped          = new D3d11MappedSubResource();
        floatPointer    = null;
        floatCursor     = 0;
        lastUnmapCursor = 0;
        baseFloatCursor = 0;
    }

    public function map()
    {
        final flag  = if (floatCursor == 0) D3d11Map.WriteDiscard else D3d11Map.WriteNoOverwrite;
        var result  = Ok;
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

    public function getVerticesWritten()
    {
        return cpp.NativeMath.idiv(floatCursor - lastUnmapCursor, VERTEX_STRIDE);
    }

    public function getBaseVertex()
    {
        return cpp.NativeMath.idiv(baseFloatCursor, VERTEX_STRIDE);
    }

    public overload inline extern function write(_v : Float)
    {
        floatPointer[floatCursor] = _v;

        floatCursor++;
    }

    public overload inline extern function write(_v : Vec2)
    {
        floatPointer[floatCursor + 0] = _v.x;
        floatPointer[floatCursor + 1] = _v.y;

        floatCursor += 2;
    }

    public overload inline extern function write(_v : Vec3)
    {
        floatPointer[floatCursor + 0] = _v.x;
        floatPointer[floatCursor + 1] = _v.y;
        floatPointer[floatCursor + 2] = _v.z;

        floatCursor += 3;
    }

    public overload inline extern function write(_v : Vec4)
    {
        floatPointer[floatCursor + 0] = _v.x;
        floatPointer[floatCursor + 1] = _v.y;
        floatPointer[floatCursor + 2] = _v.z;
        floatPointer[floatCursor + 3] = _v.w;

        floatCursor += 4;
    }
}