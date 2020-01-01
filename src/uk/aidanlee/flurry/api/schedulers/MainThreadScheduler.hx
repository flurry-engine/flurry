package uk.aidanlee.flurry.api.schedulers;

import haxe.Timer;
import rx.Subscription;
import rx.schedulers.Base;
import rx.schedulers.MakeScheduler;
import rx.disposables.ISubscription;

class MainThreadScheduler extends MakeScheduler
{
    public function new()
    {
        super(new MainThreadBase());
    }
}

private class MainThreadBase implements Base
{
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
        Flurry.dispatch.add(_action);

        return Subscription.empty();
    }
}