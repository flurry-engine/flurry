package uk.aidanlee.flurry.api.buffers;

import haxe.io.Bytes;

@:forward(changed, bytes, byteOffset, byteLength)
abstract Float32BufferData(BufferData) from BufferData to BufferData
{
    /**
     * The number of bytes per float32 element.
     */
    public static final BYTES_PER_FLOAT = 4;

    /**
     * The offset in floats this buffer is into the underlying bytes.
     */
    public var offset (get, set) : Int;

    inline function get_offset() : Int return cast this.byteOffset / BYTES_PER_FLOAT;

    inline function set_offset(_v : Int) : Int
    {
        this.byteOffset = _v * BYTES_PER_FLOAT;

        return _v;
    }

    /**
     * The length in floats this buffer contains in underlying bytes.
     */
    public var length (get, set) : Int;

    inline function get_length() : Int return cast this.byteLength / BYTES_PER_FLOAT;

    inline function set_length(_v : Int) : Int
    {
        this.byteLength = _v * BYTES_PER_FLOAT;

        return _v;
    }

    public function new(_length : Int)
    {
        this = new BufferData(Bytes.alloc(_length * BYTES_PER_FLOAT), 0, _length * BYTES_PER_FLOAT);
    }

    public function sub(_begin : Int, _length : Int) : Float32BufferData
    {
        return this.sub(_begin * BYTES_PER_FLOAT, _length * BYTES_PER_FLOAT);
    }

    public function subarray(_begin : Int, _end : Int) : Float32BufferData
    {
        return this.subarray(_begin * BYTES_PER_FLOAT, _end * BYTES_PER_FLOAT);
    }

    @:arrayAccess public inline function get(_idx : Int) : Float
    {
#if cpp
        return untyped __global__.__hxcpp_memory_get_float(this.bytes.getData(), (_idx << 2) + this.byteOffset);
#else
        return this.bytes.getFloat((_idx << 2) + this.byteOffset);
#end
    }

    @:arrayAccess public inline function set(_idx : Int, _val : Float) : Float
    {
#if cpp
        untyped __global__.__hxcpp_memory_set_float(this.bytes.getData(), (_idx << 2) + this.byteOffset, _val);
#else
        this.bytes.setFloat((_idx << 2) + this.byteOffset, _val);
#end

        this.changed.dispatch();

        return _val;
    }
}