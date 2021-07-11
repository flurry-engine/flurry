package uk.aidanlee.flurry.api.resources;

typedef ResourceID = Int;

class Resource
{
    public final id : ResourceID;

    public function new(_id)
    {
        id = _id;
    }
}