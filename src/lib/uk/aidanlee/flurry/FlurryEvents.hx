package uk.aidanlee.flurry;

import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.display.DisplayEvents;

class FlurryEvents
{
    public final input : InputEvents;

    public final resource : ResourceEvents;

    public final display : DisplayEvents;

    public function new()
    {
        input    = new InputEvents();
        resource = new ResourceEvents();
        display  = new DisplayEvents();
    }
}
