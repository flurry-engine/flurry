package uk.aidanlee.flurry.api.gpu.backend.ogl3.output;

import uk.aidanlee.flurry.api.maths.Maths.nextMultipleOff;
import haxe.io.ArrayBufferView;
import opengl.OpenGL.*;

@:nullSafety(Off) class UniformOutput
{
    public final buffer : Int;

    final length : Int;

    final alignment : Int;

    var voidPointer : cpp.Star<cpp.Void>;

    var byteCursor : Int;

    var lastUnmapCursor : Int;

    public function new(_buffer, _length, _alignment)
    {
        buffer          = _buffer;
        length          = _length;
        alignment       = _alignment;
        voidPointer     = null;
        byteCursor      = 0;
    }

    public function map()
    {
        final flag = if (byteCursor == 0) GL_MAP_INVALIDATE_BUFFER_BIT else GL_MAP_UNSYNCHRONIZED_BIT;
        final ptr  = glMapBufferRange(GL_UNIFORM_BUFFER, 0, length, GL_MAP_WRITE_BIT | flag);

        voidPointer = ptr;
    }

    public function unmap()
    {
        glUnmapBuffer(GL_UNIFORM_BUFFER);
    }

    public function close()
    {
        byteCursor = 0;
    }
    
    public function write(_buffer : ArrayBufferView)
    {
        final currentPos  = byteCursor;
        final srcPos      = _buffer.byteOffset;
        final length      = _buffer.byteLength;
        final dstPtr      = (cpp.Pointer.fromStar(voidPointer).reinterpret() : cpp.Pointer<cpp.UInt8>).add(byteCursor);
        
        cpp.Native.memcpy(
            dstPtr,
            cpp.NativeArray.address(_buffer.buffer.getData(), srcPos),
            length);

        byteCursor = nextMultipleOff(byteCursor + length, alignment);

        return currentPos;
    }
}