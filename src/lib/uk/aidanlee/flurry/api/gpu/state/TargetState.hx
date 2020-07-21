package uk.aidanlee.flurry.api.gpu.state;

import uk.aidanlee.flurry.api.resources.Resource.ResourceID;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

enum TargetState
{
    Backbuffer;
    Texture(_image : ResourceID);
}