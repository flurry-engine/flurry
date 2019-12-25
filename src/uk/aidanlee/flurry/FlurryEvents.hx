package uk.aidanlee.flurry;

import rx.Subject;
import rx.Observable;
import rx.subjects.Replay;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.display.DisplayEvents;

class FlurryEvents
{
    public final init : Observable<Unit>;

    public final ready : Observable<Unit>;

    public final preUpdate : Observable<Unit>;

    public final update : Observable<Float>;

    public final postUpdate : Observable<Unit>;

    public final shutdown : Observable<Unit>;

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
