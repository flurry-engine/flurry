package uk.aidanlee.flurry.api.schedulers;

import haxe.Timer;
import hxrx.ISubscription;
import hxrx.schedulers.IScheduler;
import hxrx.subscriptions.Single;
import hx.concurrent.executor.Executor;

using Safety;

class ThreadPoolScheduler implements IScheduler
{
    final pool : Executor;

    public function new(_pool)
    {
        pool = _pool;
    }

    public function time()
    {
        return Timer.stamp();
    }

    public function scheduleNow(_action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final future = pool.submit(_action.bind(this));

        return new Single(future.cancel);
    }

    public function scheduleAt(_dueTime : Date, _action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final diff   = Std.int(_dueTime.getTime() - Date.now().getTime());
        final future = pool.submit(_action.bind(this), ONCE(diff));

        return new Single(future.cancel);
    }

    public function scheduleIn(_dueTime : Float, _action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final time   = Std.int(_dueTime * 1000);
        final future = pool.submit(_action.bind(this), ONCE(time));

        return new Single(future.cancel);
    }
}