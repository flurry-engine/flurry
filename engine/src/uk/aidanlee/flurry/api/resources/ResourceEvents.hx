package uk.aidanlee.flurry.api.resources;

enum abstract ResourceEvents(String) from String to String
{
    var Created = 'flurry-resource-created';

    var Removed = 'flurry-resource-removed';
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
