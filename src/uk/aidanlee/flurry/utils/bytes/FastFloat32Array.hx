package uk.aidanlee.flurry.utils.bytes;

import haxe.io.BytesData;
import signals.Signal.Signal0;
import haxe.io.Bytes;

/**
 * Simple float32 typed array wrapped around bytes.
 * Does not contain all the fancy view stuff that usual typed buffers do.
 * Will not perform any bounds checking on cpp for speed.
 * Mainly used by the maths classes where you don't usually directly index into the array.
 * 
 * `changed` signal can also be listened to for when values change.
 */
@:forward(getData, length, changed)
abstract FastFloat32Array(ObservableBytes) from ObservableBytes to ObservableBytes
{
    public static final BYTES_PER_ELEMENT = 4;

    public function new(_elements : Int)
    {
        this = ObservableBytes.alloc(_elements * BYTES_PER_ELEMENT);
    }

	@:arrayAccess public inline function get(_index : Int) : Float
    {
#if cpp
        return untyped __global__.__hxcpp_memory_get_float(this.getData(), _index << 2);
#else
		return this.getFloat(_index << 2);
#end
	}

	@:arrayAccess public inline function set(_index : Int, _value : Float) : Float
    {
		if (get(_index) != _value)
		{
#if cpp
        	untyped __global__.__hxcpp_memory_set_float(this.getData(), _index << 2, _value);
#else
        	this.setFloat(_index << 2, _value);
#end        
        	this.changed.dispatch();
		}

        return _value;
	}
}

private class ObservableBytes extends Bytes
{
    public final changed = new Signal0();

	/**
	 * Returns a new `Bytes` instance with a fixed length.
	 * bytes are not initialized and may not be zero.
	 * @param _length The number of bytes to be allocated.
	 * @return ObservableBytes
	 */
	public static function alloc(_length : Int) : ObservableBytes
	{
		#if neko
		return new ObservableBytes(_length, untyped __dollar__smake(_length));
		#elseif flash
		var b = new flash.utils.ByteArray();
		b.length = _length;
		return new ObservableBytes(_length, b);
		#elseif cpp
		var a = new BytesData();
		if (_length > 0)
			cpp.NativeArray.setSize(a, _length);
		return new ObservableBytes(_length, a);
		#elseif cs
		return new ObservableBytes(_length, new cs.NativeArray(_length));
		#elseif java
		return new ObservableBytes(_length, new java.NativeArray(_length));
		#elseif python
		return new ObservableBytes(_length, new python.Bytearray(_length));
		#else
		var a = new Array();
		for (i in 0..._length)
			a.push(0);
		return new ObservableBytes(_length, cast a);
		#end
	}
}
