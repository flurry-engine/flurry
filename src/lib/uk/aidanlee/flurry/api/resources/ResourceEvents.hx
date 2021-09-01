package uk.aidanlee.flurry.api.resources;

import uk.aidanlee.flurry.api.resources.Resource;
import hxrx.subjects.PublishSubject;

class ResourceEvents
{
    public final created : PublishSubject<Resource>;

    public final removed : PublishSubject<Resource>;

    public function new()
    {
        created = new PublishSubject();
        removed = new PublishSubject();
    }
}
