package uk.aidanlee.flurry.api.buffers;

import haxe.io.Bytes;

@:forward(changed, bytes, byteOffset, byteLength)
abstract UInt16BufferData(BufferData) from BufferData to BufferData
{
    /**
     * The number of bytes per UInt16 element.
     */
    public static final BYTES_PER_UINT = 2;

    /**
     * The offset in floats this buffer is into the underlying bytes.
     */
    public var offset (get, set) : Int;

    inline function get_offset() : Int return cast this.byteOffset / BYTES_PER_UINT;

    inline function set_offset(_v : Int) : Int
    {
        this.byteOffset = _v * BYTES_PER_UINT;

        return _v;
    }

    /**
     * The length in floats this buffer contains in underlying bytes.
     */
    public var length (get, set) : Int;

    inline function get_length() : Int return cast this.byteLength / BYTES_PER_UINT;

    inline function set_length(_v : Int) : Int
    {
        this.byteLength = _v * BYTES_PER_UINT;

        return _v;
    }

    public function new(_length : Int)
    {
        this = new BufferData(Bytes.alloc(_length * BYTES_PER_UINT), 0, _length * BYTES_PER_UINT);
    }

    public function sub(_begin : Int, _length : Int) : UInt16BufferData
    {
        return this.sub(_begin * BYTES_PER_UINT, _length * BYTES_PER_UINT);
    }

    public function subarray(_begin : Int, _end : Int) : UInt16BufferData
    {
        return this.subarray(_begin * BYTES_PER_UINT, _end * BYTES_PER_UINT);
    }

    public function get(_idx : Int) : Int
    {
#if cpp
        return untyped __global__.__hxcpp_memory_get_ui16(this.bytes.getData(), (_idx << 1) + this.byteOffset);
#else
        return bytes.getUInt16((_idx << 1) + this.byteOffset);
#end
    }

    public function set(_idx : Int, _val : Int) : Int
    {
#if cpp
        untyped __global__.__hxcpp_memory_set_ui16(this.bytes.getData(), (_idx << 1) + this.byteOffset, _val);
#else
        bytes.setUInt16((_idx << 1) + this.byteOffset, _val);
#end

        this.changed.dispatch();

        return _val;
    }
}