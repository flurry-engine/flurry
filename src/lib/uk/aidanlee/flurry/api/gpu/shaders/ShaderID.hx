package uk.aidanlee.flurry.api.gpu.shaders;

import uk.aidanlee.flurry.api.resources.ResourceID;

abstract ShaderID(ResourceID) to ResourceID to Int
{
    public function new(_resourceID)
    {
        this = _resourceID;
    }
}