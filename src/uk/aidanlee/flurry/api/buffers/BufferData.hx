package uk.aidanlee.flurry.api.buffers;

import signals.Signal.Signal0;
import haxe.io.Bytes;

class BufferData
{
    public final changed : Signal0;

    public final bytes : Bytes;

    public var byteOffset : Int;

    public var byteLength : Int;

    public function new(_bytes : Bytes, _offset : Int, _length : Int)
    {
        changed    = new Signal0();
        bytes      = _bytes;
        byteOffset = _offset;
        byteLength = _length;
    }

    public function sub(_begin : Int, _length : Int) : BufferData
    {
        return new BufferData(bytes, byteOffset + _begin, _length);
    }

    public function subarray(_begin : Int, _end : Int) : BufferData
    {
        return new BufferData(bytes, byteOffset + _begin, _end - _begin);
    }
}