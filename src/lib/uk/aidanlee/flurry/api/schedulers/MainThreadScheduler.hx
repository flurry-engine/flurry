package uk.aidanlee.flurry.api.schedulers;

import rx.Subscription;
import rx.schedulers.ISchedulerBase;
import rx.schedulers.MakeScheduler;
import rx.schedulers.TimedAction;
import rx.disposables.ISubscription;
import haxe.Timer;
import haxe.ds.ArraySort;
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

    var resort : Bool;

    public function new()
    {
        tasks     = [];
        queueLock = new Mutex();
        resort    = false;
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

        // Since we sort in descending order any actions with a due time of 0 will naturally appear at the end of the list.
        // As we're pushing to the end of the list we don't need to force a resort since it will already be in the correct order.
        if (_dueTime != 0)
        {
            resort = true;
        }
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
     */
    public function dispatch()
    {
        queueLock.acquire();

        if (tasks.length > 0)
        {
            if (resort)
            {
                // Sort in descending order, actions closest to execution time will be at the bottom of the array.
                ArraySort.sort(tasks, (a1, a2) -> Std.int(a2.execTime - a1.execTime));

                resort = false;
            }
            
            final currentTime = now();
            
            var dispatchable = 0;
            var length       = tasks.length;

            // Iterate starting at the end of the list to find the first item ready for execution.
            while (length > 0)
            {
                final action = tasks[length - 1];

                if (action.execTime <= currentTime)
                {
                    dispatchable++;
                    length--;
                }
                else
                {
                    break;
                }
            }

            // If we have actions which can be dispatched loop forward from the first found action index to the end.
            // We can then safely resize by the amount dispatched since we have a sorted array and initially searched back to front.
            if (dispatchable > 0)
            {
                for (i in length...tasks.length)
                {
                    tasks[i].discardableAction();
                }

                tasks.resize(tasks.length - dispatchable);
            }
        }

        queueLock.release();
    }
}
