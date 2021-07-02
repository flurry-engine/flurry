package uk.aidanlee.flurry.api.resources;

import uk.aidanlee.flurry.api.resources.builtin.DataBlob;
import uk.aidanlee.flurry.api.resources.Resource;
import hxrx.subjects.PublishSubject;

class ResourceEvents
{
    public final created : PublishSubject<Resource>;

    public final removed : PublishSubject<Resource>;

    public final pageCreated : PublishSubject<DataBlob>;

    public final pageRemoved : PublishSubject<String>;

    public final shaderCreated : PublishSubject<DataBlob>;

    public final shaderRemoved : PublishSubject<String>;

    public function new()
    {
        created       = new PublishSubject();
        removed       = new PublishSubject();
        pageCreated   = new PublishSubject();
        pageRemoved   = new PublishSubject();
        shaderCreated = new PublishSubject();
        shaderRemoved = new PublishSubject();
    }
}
