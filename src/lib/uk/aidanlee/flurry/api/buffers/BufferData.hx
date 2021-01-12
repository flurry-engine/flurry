package uk.aidanlee.flurry.api.buffers;

import haxe.io.Bytes;
import hxrx.IObserver;
import hxrx.IObservable;
import hxrx.ISubscription;
import hxrx.subjects.PublishSubject;
import uk.aidanlee.flurry.api.core.Unit;

class BufferData implements IObservable<Unit>
{
    public final changed : PublishSubject<Unit>;

    public final bytes : Bytes;

    public var byteOffset : Int;

    public var byteLength : Int;

    public function new(_bytes : Bytes, _offset : Int, _length : Int)
    {
        changed    = new PublishSubject();
        bytes      = _bytes;
        byteOffset = _offset;
        byteLength = _length;
    }

    public function subscribe(_observer : IObserver<Unit>) : ISubscription
    {
        return changed.subscribe(_observer);
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