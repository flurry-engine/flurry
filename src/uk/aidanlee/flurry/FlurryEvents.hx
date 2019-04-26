package uk.aidanlee.flurry;

import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import signals.Signal;

class FlurryEvents
{
    public final init : Signal0;

    public final ready : Signal0;

    public final preUpdate : Signal0;

    public final update : Signal0;

    public final postUpdate : Signal0;

    public final shutdown : Signal0;

    public final input : InputEvents;

    public final resource : ResourceEvents;

    public final display : DisplayEvents;

    public function new()
    {
        init       = new Signal0();
        ready      = new Signal0();
        preUpdate  = new Signal0();
        update     = new Signal0();
        postUpdate = new Signal0();
        shutdown   = new Signal0();
        input      = new InputEvents();
        resource   = new ResourceEvents();
        display    = new DisplayEvents();
    }
}
