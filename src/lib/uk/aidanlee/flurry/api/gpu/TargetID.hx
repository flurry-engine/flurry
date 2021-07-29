package uk.aidanlee.flurry.api.gpu;

import uk.aidanlee.flurry.api.resources.ResourceID;

abstract TargetID(ResourceID) to ResourceID to Int
{
    public static final backbuffer = new TargetID(ResourceID.invalid);

    public function new(_resourceID)
    {
        this = _resourceID;
    }
}