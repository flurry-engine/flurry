package uk.aidanlee.flurry.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;
import uk.aidanlee.flurry.api.gpu.state.TargetState;

interface IBatchable
{
    function getDepth() : Float;

    function getTarget() : TargetState;

    function getShader() : ResourceID;

    function batch(_queue : DrawCommand->Void) : Void;
}