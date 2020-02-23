package uk.aidanlee.flurry.api.buffers;

import rx.Unit;
import rx.Subject;
import rx.observers.IObserver;
import rx.disposables.ISubscription;
import rx.observables.IObservable;
import haxe.io.Bytes;

class BufferData implements IObservable<Unit>
{
    public final changed : Subject<Unit>;

    public final bytes : Bytes;

    public var byteOffset : Int;

    public var byteLength : Int;

    public function new(_bytes : Bytes, _offset : Int, _length : Int)
    {
        changed    = Subject.create();
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

    public function subscribe(_observer : IObserver<Unit>) : ISubscription
    {
        return changed.subscribe(_observer);
    }
}