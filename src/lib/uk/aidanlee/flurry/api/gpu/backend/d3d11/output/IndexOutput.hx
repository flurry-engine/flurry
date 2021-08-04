package uk.aidanlee.flurry.api.gpu.backend.d3d11.output;

import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11MappedSubResource;
import d3d11.enumerations.D3d11Map;

@:nullSafety(Off) class IndexOutput
{
    static inline var SHORT_BYTES_SIZE = 4;

    final context : D3d11DeviceContext1;

    final buffer : D3d11Buffer;

    final mapped : D3d11MappedSubResource;

    var shortOffset : cpp.UInt16;

    var shortPointer : cpp.RawPointer<cpp.UInt16>;

    var shortCursor : Int;

    var lastUnmapCursor : Int;

    var baseIndexCuror : Int;

    public function new(_context, _buffer)
    {
        context         = _context;
        buffer          = _buffer;
        mapped          = new D3d11MappedSubResource();
        shortOffset     = 0;
        shortPointer    = null;
        shortCursor     = 0;
        lastUnmapCursor = 0;
        baseIndexCuror  = 0;
    }

    public function map()
    {
        final flag = if (shortCursor == 0) D3d11Map.WriteDiscard else D3d11Map.WriteNoOverwrite;
        var result = Ok;
        if (Ok != (result = context.map(buffer, 0, flag, 0, mapped)))
        {
            throw new Exception('Failed to map D3D11 index buffer : HRESULT $result');
        }

        baseIndexCuror = shortCursor;
        shortPointer   = cast mapped.data.raw;
    }

    public function unmap()
    {
        context.unmap(buffer, 0);

        lastUnmapCursor = shortCursor;
    }

    public function close()
    {
        shortCursor     = 0;
        lastUnmapCursor = 0;
        baseIndexCuror  = 0;
    }

    public function getIndicesWritten()
    {
        return shortCursor - lastUnmapCursor;
    }

    public function getBaseIndex()
    {
        return baseIndexCuror;
    }

    public function offset(_v : Int)
    {
        shortOffset = _v;
    }

    public function write(_v : Int)
    {
        shortPointer[shortCursor] = shortOffset + _v;

        shortCursor++;
    }
}