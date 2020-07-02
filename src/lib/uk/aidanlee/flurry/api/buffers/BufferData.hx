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
        changed    = new Subject<Unit>();
        bytes      = _bytes;
        byteOffset = _offset;
        byteLength = _length;
    }

    public function subscribe(_observer : IObserver<Unit>) : ISubscription
    {
        return changed.subscribe(_observer);
    }
}