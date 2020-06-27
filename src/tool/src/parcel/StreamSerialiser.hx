package parcel;

import hxbit.Serializable;
import haxe.io.Bytes;
import haxe.ds.Vector;
import haxe.Int64;
import haxe.io.Output;
import hxbit.Serializer;

@:nullSafety(Off) class StreamSerialiser extends Serializer
{
    var oStream : Output;

    public function streamSerialise(_stream : Output, _object : Serializable)
    {
        oStream = _stream;

        begin();
        addKnownRef(_object);
    }

    override function addByte(v:Int) {
        oStream.writeByte(v);
    }

    override function addInt(v:Int) {
        if( v >= 0 && v < 0x80 )
			oStream.writeByte(v);
		else {
			oStream.writeByte(0x80);
			oStream.writeInt32(v);
		}
    }

    override function addInt32(v:Int) {
        oStream.writeInt32(v);
    }

    override function addInt64(v:Int64) {
        oStream.writeInt32(v.low);
        oStream.writeInt32(v.high);
    }

    override function addFloat(v:Float) {
        oStream.writeFloat(v);
    }

    override function addDouble(v:Float) {
        oStream.writeDouble(v);
    }

    override function addBool(v:Bool) {
        addByte(if (v) 1 else 0);
    }

    override function addArray<T>(a:Array<T>, f:T -> Void) {
        if (a == null) {
            addByte(0);

            return;
        }

        addInt(a.length + 1);

        for (v in a)
        {
            f(v);
        }
    }

    override function addVector<T>(a:Vector<T>, f:T -> Void) {
        if (a == null) {
            addByte(0);

            return;
        }

        addInt(a.length + 1);

        for (v in a)
        {
            f(v);
        }
    }

    override function addMap<K, T>(a:Map<K, T>, fk:K -> Void, ft:T -> Void) {
        if( a == null ) {
			addByte(0);
			return;
		}
		var keys = [for (k in a.keys()) k];
		addInt(keys.length + 1);
		for( k in keys ) {
			fk(k);
			ft(a.get(k));
		}
    }

    override function addString(s:String) {
        if( s == null )
			addByte(0);
		else {
			var b = haxe.io.Bytes.ofString(s);
			addInt(b.length + 1);
			oStream.writeBytes(b, 0, b.length);
		}
    }

    override function addBytes(b:Bytes) {
        if( b == null )
			addByte(0);
		else {
			addInt(b.length + 1);
			oStream.writeBytes(b, 0, b.length);
		}
    }

    override function addBytesSub(b:Bytes, pos:Int, len:Int) {
		if( b == null )
			addByte(0);
		else {
			addInt(len + 1);
			oStream.writeBytes(b, pos, len);
		}
    }
}