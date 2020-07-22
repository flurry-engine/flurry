package uk.aidanlee.flurry.api.gpu.state;

import uk.aidanlee.flurry.api.resources.Resource.ResourceID;

enum TargetState
{
    Backbuffer;
    Texture(_image : ResourceID);
}