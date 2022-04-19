package uk.aidanlee.flurry.api.resources.builtin;

import haxe.io.Bytes;

class DataBlobResource extends Resource
{
    public final resource : Resource;

    public final data : Bytes;

    public function new(_resource, _data)
    {
        super(ResourceID.invalid);

        resource = _resource;
        data     = _data;
    }
}