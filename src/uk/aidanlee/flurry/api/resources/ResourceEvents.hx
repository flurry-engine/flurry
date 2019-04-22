package uk.aidanlee.flurry.api.resources;

import petesignals.Signal1;

class ResourceEvents
{
    public final created : Signal1<ResourceEventCreated>;

    public final removed : Signal1<ResourceEventRemoved>;

    public function new()
    {
        created = new Signal1<ResourceEventCreated>();
        removed = new Signal1<ResourceEventRemoved>();
    }
}

class ResourceEventCreated
{
    public final type : Class<Resource>;

    public final resource : Resource;

    public function new(_type : Class<Resource>, _resource : Resource)
    {
        type     = _type;
        resource = _resource;
    }
}

class ResourceEventRemoved
{
    public final type : Class<Resource>;

    public final resource : Resource;

    public function new(_type : Class<Resource>, _resource : Resource)
    {
        type     = _type;
        resource = _resource;
    }
}
