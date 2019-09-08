package uk.aidanlee.flurry.api.resources;

import signals.Signal1;

class ResourceEvents
{
    public final created : Signal1<Resource>;

    public final removed : Signal1<Resource>;

    public function new()
    {
        created = new Signal1<Resource>();
        removed = new Signal1<Resource>();
    }
}
