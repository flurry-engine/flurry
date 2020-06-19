package uk.aidanlee.flurry.api.schedulers;

import rx.Subscription;
import rx.schedulers.ISchedulerBase;
import rx.schedulers.MakeScheduler;
import rx.schedulers.TimedAction;
import rx.disposables.ISubscription;
import haxe.Timer;
import sys.thread.Mutex;

class MainThreadScheduler extends MakeScheduler
{
    public static final current = new MainThreadScheduler();
    
    function new()
    {
        super(new MainThreadBase());
    }

    public function dispatch()
    {
        (cast baseScheduler : MainThreadBase).dispatch();
    }
}

private class MainThreadBase implements ISchedulerBase
{
    /**
     * All of the timed actions queued for execution on the main thread.
     * After a call to `dispatch` they will be sorted by `execTime` in descending order.
     */
    final tasks : Array<TimedAction>;

    final queueLock : Mutex;

    public function new()
    {
        tasks     = [];
        queueLock = new Mutex();
    }

    public function now()
    {
        return Timer.stamp();
    }

    public function scheduleAbsolute(_dueTime : Float, _action : () -> Void) : ISubscription
    {
        final task = new TimedAction(_action, _dueTime);

        queueLock.acquire();
        tasks.push(task);
        queueLock.release();

        return Subscription.create(() -> {
            queueLock.acquire();
            tasks.remove(task);
            queueLock.release();
        });
    }

    /**
     * Loops over all tasks and executes any if the exec time is due.
     * If a new task has been scheduled then we will re-sort the list before searching.
     * This allows us to exit the loop as soon as the first tasks which isn't due appears.
     * Also makes reverse looping and popping tasks off the end of the array easy.
     */
    public function dispatch()
    {
        queueLock.acquire();

        final currentTime = now();

        for (action in tasks.copy())
        {
            if (action.execTime <= currentTime)
            {
                action.discardableAction();

                tasks.remove(action);
            }
        }

        queueLock.release();
    }
}
