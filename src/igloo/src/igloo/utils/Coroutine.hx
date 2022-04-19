package igloo.utils;

import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.Future.FutureResult;
import hx.concurrent.executor.Executor;

class ConcurrentTaskReturn<T : {}>
{
    public final resume : T->Void;

    public final value : T;

    public function new(_resume, _value)
    {
        resume = _resume;
        value  = _value;
    }
}

class CountedConcurrentTaskReturn<T : {}>
{
    public final resume : Array<T>->Void;

    public final counter : AtomicInt;

    public final values : SynchronizedArray<T>;

    public function new(_resume, _counter)
    {
        resume  = _resume;
        counter = _counter;
        values  = new SynchronizedArray();
    }
}

@:pecan.accept function async<T : {}>(_executor : Executor, _task : Void->T, ?_ret : T->Void, ?_co:pecan.ICo<Any, Any, Any>)
{
    final future = _executor.submit(() -> {
        final value   = _task();
        final counter = new ConcurrentTaskReturn(_ret, value);

        return counter;
    });

    future.onResult = onAsyncResult;

    return null;
}

@:pecan.accept function asyncs<T : {}>(_executor : Executor, _tasks : Array<Void->T>, ?_ret : Array<T>->Void, ?_co:pecan.ICo<Any, Any, Any>)
{
    final counter = new AtomicInt(_tasks.length);
    final storage = new CountedConcurrentTaskReturn(_ret, counter);

    for (task in _tasks)
    {
        final future = _executor.submit(() -> {
            storage.values.add(task());

            return storage;
        });

        future.onResult = onAsyncsResult;
    }

    return null;
}

private function onAsyncResult<T : {}>(_result : FutureResult<ConcurrentTaskReturn<T>>)
{
    switch _result
    {
        case SUCCESS(result, _, _):
            result.resume(result.value);
        case FAILURE(_, _, _):
            //
        case NONE(_):
            //
    }
}

private function onAsyncsResult<T : {}>(_result : FutureResult<CountedConcurrentTaskReturn<T>>)
{
    switch _result {
        case SUCCESS(result, _, _):
            if (result.counter.decrementAndGet() == 0)
            {
                result.resume(result.values.toArray());
            }
        case FAILURE(_, _, _):
            //
        case NONE(_):
            //
    }
}