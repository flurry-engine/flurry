package uk.aidanlee.flurry.api.gpu.backend.ogl3.output;

import opengl.OpenGL.*;
import uk.aidanlee.flurry.api.maths.Maths.nextMultipleOff;

@:nullSafety(Off) class VertexOutput
{
    public final buffer : Int;

    final length : Int;

    var floatPointer : cpp.RawPointer<cpp.Float32>;

    var floatCursor : Int;

    var floatStride : Int;

    public function new(_buffer, _length)
    {
        buffer        = _buffer;
        length        = _length;
        floatPointer  = null;
        floatCursor   = 0;
        floatStride   = -1;
    }

    public function seek(_stride : Int)
    {
        floatStride = cpp.NativeMath.idiv(_stride, 4);
        floatCursor = 0;
    }

    public function map()
    {
        final ptr = glMapBufferRange(GL_ARRAY_BUFFER, 0, length, GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_BUFFER_BIT);

        floatCursor  = 0;
        floatPointer = (cast ptr : cpp.RawPointer<cpp.Float32>);
    }

    public function unmap()
    {
        glUnmapBuffer(GL_ARRAY_BUFFER);
    }

    public function close()
    {
        floatCursor   = 0;
        floatStride   = -1;
    }

    public function getVerticesWritten()
    {
        return cpp.NativeMath.idiv(floatCursor, floatStride);
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