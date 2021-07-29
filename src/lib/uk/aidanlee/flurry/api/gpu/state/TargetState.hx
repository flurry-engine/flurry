package uk.aidanlee.flurry.api.gpu.state;

import uk.aidanlee.flurry.api.resources.ResourceID;

enum TargetState
{
    Backbuffer;
    Texture(_image : ResourceID);
}