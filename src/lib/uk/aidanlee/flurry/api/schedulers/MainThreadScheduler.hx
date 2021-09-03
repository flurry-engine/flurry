package uk.aidanlee.flurry.api.schedulers;

import sys.thread.Deque;
import haxe.Timer;
import hxrx.ISubscription;
import hxrx.schedulers.IScheduler;
import hxrx.subscriptions.Single;
import hx.concurrent.executor.Executor;

class MainThreadScheduler implements IScheduler
{
    /**
     * All of the timed actions queued for execution on the main thread.
     * After a call to `dispatch` they will be sorted by `execTime` in descending order.
     */
    final tasks : Deque<(_scheduler : IScheduler) -> ISubscription>;

    final pool : Executor;

    public function new(_pool)
    {
        tasks = new Deque();
        pool  = _pool;
    }

    public function time()
    {
        return Timer.stamp();
    }

    public function scheduleNow(_action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final future = pool.submit(enqueue.bind(_action));

        return new Single(future.cancel);
    }

    public function scheduleAt(_dueTime : Date, _action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final diff   = Std.int(_dueTime.getTime() - Date.now().getTime());
        final future = pool.submit(enqueue.bind(_action), ONCE(diff));

        return new Single(future.cancel);
    }

    public function scheduleIn(_dueTime : Float, _action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final time   = Std.int(_dueTime * 1000);
        final future = pool.submit(enqueue.bind(_action), ONCE(time));

        return new Single(future.cancel);
    }

    public function dispatch()
    {
        while (true)
        {
            switch tasks.pop(false)
            {
                case null:
                    return;
                case task:
                    task(this).unsubscribe();
            }
        }
    }

    function enqueue(_func : (_scheduler : IScheduler) -> ISubscription)
    {
        tasks.add(_func);
    }
}
