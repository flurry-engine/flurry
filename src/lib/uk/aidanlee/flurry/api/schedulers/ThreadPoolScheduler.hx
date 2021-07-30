package uk.aidanlee.flurry.api.schedulers;

import sys.thread.Mutex;
import haxe.Timer;
import hxrx.ISubscription;
import hxrx.schedulers.IScheduler;
import hxrx.schedulers.ScheduledItem;
import hxrx.subscriptions.Single;
import hx.concurrent.executor.Executor;

using Safety;

class ThreadPoolScheduler implements IScheduler
{
    final pool : Executor;

    /**
     * All of the timed actions queued for execution on the main thread.
     * After a call to `dispatch` they will be sorted by `execTime` in descending order.
     */
    final tasks : Array<ScheduledItem>;

    final queueLock : Mutex;

    var resort : Bool;

    public function new()
    {
        pool      = Executor.create(8);
        tasks     = [];
        queueLock = new Mutex();
        resort    = false;
    }

    public function time()
    {
        return Timer.stamp();
    }

    public function scheduleNow(_action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final future = pool.submit(_action.bind(this));

        return new hxrx.subscriptions.Single(future.cancel);
    }

    public function scheduleAt(_dueTime : Date, _action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final diff   = Std.int(_dueTime.getTime() - Date.now().getTime());
        final future = pool.submit(_action.bind(this), ONCE(diff));

        return new hxrx.subscriptions.Single(future.cancel);
    }

    public function scheduleIn(_dueTime : Float, _action : (_scheduler : IScheduler) -> ISubscription) : ISubscription
    {
        final time   = Std.int(_dueTime * 1000);
        final future = pool.submit(_action.bind(this), ONCE(time));

        return new hxrx.subscriptions.Single(future.cancel);
    }

    /**
     * Loops over all tasks and executes any if the exec time is due.
     * If a new task has been scheduled then we will re-sort the list before searching.
     * This allows us to exit the loop as soon as the first tasks which isn't due appears.
     */
    public function dispatch()
    {
        //
    }
}