package uk.aidanlee.flurry;

import rx.Unit;
import rx.Subject;
import rx.observables.IObservable;
import rx.subjects.Replay;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.display.DisplayEvents;

class FlurryEvents
{
    public final init : IObservable<Unit>;

    public final ready : IObservable<Unit>;

    public final preUpdate : IObservable<Unit>;

    public final update : IObservable<Float>;

    public final postUpdate : IObservable<Unit>;

    public final shutdown : IObservable<Unit>;

    public final input : InputEvents;

    public final resource : ResourceEvents;

    public final display : DisplayEvents;

    public function new()
    {
        init       = Replay.create();
        ready      = Replay.create();
        preUpdate  = Subject.create();
        update     = Subject.create();
        postUpdate = Subject.create();
        shutdown   = Replay.create();
        input      = new InputEvents();
        resource   = new ResourceEvents();
        display    = new DisplayEvents();
    }
}
