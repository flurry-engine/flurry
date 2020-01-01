package uk.aidanlee.flurry.api.schedulers;

import haxe.Timer;
import hx.concurrent.executor.Executor;
import rx.schedulers.Base;
import rx.schedulers.MakeScheduler;
import rx.disposables.Boolean;
import rx.disposables.ISubscription;

using Safety;

class ThreadPoolScheduler extends MakeScheduler
{
    public function new()
    {
        super(new ThreadPoolBase());
    }
}

private class ThreadPoolBase implements Base
{
    static final pool = Executor.create(8);

    public function new()
    {
        //
    }

    public function now()
    {
        return Timer.stamp();
    }

    public function schedule_absolute(_dueTime : Null<Float>, _action : () -> Void) : ISubscription
    {
        final task = pool.submit(_action, ONCE(Std.int(_dueTime.or(0) * 1000)));

        return Boolean.create(() -> task.cancel());
    }
}