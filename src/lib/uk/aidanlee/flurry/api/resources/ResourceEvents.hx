package uk.aidanlee.flurry.api.resources;

import rx.Subject;

class ResourceEvents
{
    public final created : Subject<Resource>;

    public final removed : Subject<Resource>;

    public function new()
    {
        created = new Subject();
        removed = new Subject();
    }
}
