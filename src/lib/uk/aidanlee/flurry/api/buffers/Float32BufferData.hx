package uk.aidanlee.flurry.api.buffers;

import haxe.io.Bytes;

@:forward(bytes, byteOffset, byteLength, subscribe, changed)
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

    inline function get_offset() return Std.int(this.byteOffset / BYTES_PER_FLOAT);

    inline function set_offset(v) return this.byteOffset = v * BYTES_PER_FLOAT;

    /**
     * The length in floats this buffer contains in underlying bytes.
     */
    public var length (get, set) : Int;

    inline function get_length() return Std.int(this.byteLength / BYTES_PER_FLOAT);

    inline function set_length(v) return this.byteLength = v * BYTES_PER_FLOAT;

    /**
     * Create a new float buffer of a fixed size.
     * @param _length Maximum number of 32bit floats in this buffer.
     */
    public function new(_length : Int)
    {
        this = new BufferData(Bytes.alloc(_length * BYTES_PER_FLOAT), 0, _length * BYTES_PER_FLOAT);
    }

    /**
     * Allows editing the buffer data without generating excess `changed` calls.
     * A new valued is passed through the `changed` observable after the provided function has been called.
     * @param _func Function to modify the buffer in.
     */
    public inline function edit(_func : (_access : Float32BufferAccess)->Void) : Float32BufferData
    {
        _func(this);

        this.changed.onNext(unit);

        return this;
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
        this.changed.onNext(unit);

        return _val;
    }
}

abstract Float32BufferAccess(BufferData) from BufferData
{
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
        return _val;
    }
}