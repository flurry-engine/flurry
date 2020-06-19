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
        init       = new Replay<Unit>();
        ready      = new Replay<Unit>();
        preUpdate  = new Subject<Unit>();
        update     = new Subject<Float>();
        postUpdate = new Subject<Unit>();
        shutdown   = new Replay<Unit>();
        input      = new InputEvents();
        resource   = new ResourceEvents();
        display    = new DisplayEvents();
    }
}
