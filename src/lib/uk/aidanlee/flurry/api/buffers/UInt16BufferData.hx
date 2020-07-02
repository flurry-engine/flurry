package uk.aidanlee.flurry.api.buffers;

import haxe.io.Bytes;

@:forward(bytes, byteOffset, byteLength, subscribe)
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

    inline function get_offset() return Std.int(this.byteOffset / BYTES_PER_UINT);

    inline function set_offset(v) return this.byteOffset = v * BYTES_PER_UINT;

    /**
     * The length in floats this buffer contains in underlying bytes.
     */
    public var length (get, set) : Int;

    inline function get_length() return Std.int(this.byteLength / BYTES_PER_UINT);

    inline function set_length(v) return this.byteLength = v * BYTES_PER_UINT;

    /**
     * Create a new int buffer of a fixed size.
     * @param _length Maximum number of 16bit ints in this buffer.
     */
    public function new(_length : Int)
    {
        this = new BufferData(Bytes.alloc(_length * BYTES_PER_UINT), 0, _length * BYTES_PER_UINT);
    }

    /**
     * Allows editing the buffer data without generating excess `changed` calls.
     * A new valued is passed through the `changed` observable after the provided function has been called.
     * @param _func Function to modify the buffer in.
     */
    public function edit(_func : (_access : UInt16BufferAccess)->Void)
    {
        _func(this);

        this.changed.onNext(unit);
    }

    public function sub(_begin : Int, _length : Int) : UInt16BufferData
    {
        return this.sub(_begin * BYTES_PER_UINT, _length * BYTES_PER_UINT);
    }

    public function subarray(_begin : Int, _end : Int) : UInt16BufferData
    {
        return this.subarray(_begin * BYTES_PER_UINT, _end * BYTES_PER_UINT);
    }

    @:arrayAccess public function get(_idx : Int) : Int
    {
#if cpp
        return untyped __global__.__hxcpp_memory_get_ui16(this.bytes.getData(), (_idx << 1) + this.byteOffset);
#else
        return this.bytes.getUInt16((_idx << 1) + this.byteOffset);
#end
    }

    @:arrayAccess public function set(_idx : Int, _val : Int) : Int
    {
#if cpp
        untyped __global__.__hxcpp_memory_set_ui16(this.bytes.getData(), (_idx << 1) + this.byteOffset, _val);
#else
        this.bytes.setUInt16((_idx << 1) + this.byteOffset, _val);
#end

        this.changed.onNext(unit);

        return _val;
    }
}
abstract UInt16BufferAccess(BufferData) from BufferData
{
    @:arrayAccess public function get(_idx : Int) : Int
    {
#if cpp
        return untyped __global__.__hxcpp_memory_get_ui16(this.bytes.getData(), (_idx << 1) + this.byteOffset);
#else
        return this.bytes.getUInt16((_idx << 1) + this.byteOffset);
#end
    }

    @:arrayAccess public function set(_idx : Int, _val : Int) : Int
    {
#if cpp
        untyped __global__.__hxcpp_memory_set_ui16(this.bytes.getData(), (_idx << 1) + this.byteOffset, _val);
#else
        this.bytes.setUInt16((_idx << 1) + this.byteOffset, _val);
#end

        return _val;
    }
}