package uk.aidanlee.flurry.api.resources;

import uk.aidanlee.flurry.api.maths.Hash;

typedef ResourceID = Int;

class Resource
{
    public final name : String;

    public final id : ResourceID;

    public function new(_name)
    {
        name      = _name;
        id        = Hash.hash(name);
    }
}