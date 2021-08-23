package uk.aidanlee.flurry.api.gpu.backend.ogl3.output;

import opengl.OpenGL.*;
import uk.aidanlee.flurry.api.maths.Maths.nextMultipleOff;

@:nullSafety(Off) class VertexOutput
{
    public final buffer : Int;

    final length : Int;

    var floatPointer : cpp.RawPointer<cpp.Float32>;

    var floatCursor : Int;

    var floatsWritten : Int;

    var baseVertex : Int;

    var floatStride : Int;

    var discard : Bool;

    public function new(_buffer, _length)
    {
        buffer        = _buffer;
        length        = _length;
        floatPointer  = null;
        floatCursor   = 0;
        floatsWritten = 0;
        baseVertex    = 0;
        floatStride   = -1;
        discard       = true;
    }

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

    public function map()
    {
        final flag = if (discard) GL_MAP_INVALIDATE_BUFFER_BIT else GL_MAP_UNSYNCHRONIZED_BIT;
        final ptr  = glMapBufferRange(GL_ARRAY_BUFFER, 0, length, GL_MAP_WRITE_BIT | flag);

        baseVertex    = cpp.NativeMath.idiv(floatsWritten, floatStride);
        floatsWritten = 0;
        floatPointer  = (cast ptr : cpp.RawPointer<cpp.Float32>);
        discard       = false;
    }

    public function unmap()
    {
        glUnmapBuffer(GL_ARRAY_BUFFER);
    }

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