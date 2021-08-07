package uk.aidanlee.flurry.api.gpu;

import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.resources.ResourceID;

@:build(uk.aidanlee.flurry.macros.ApiSelector.buildGraphicsContextOutputs())
abstract class GraphicsContext
{
    function new(_vtxOutput, _idxOutput)
    {
        vtxOutput = _vtxOutput;
        idxOutput = _idxOutput;
    }

    public abstract function usePipeline(_id : PipelineID) : Void;

    public abstract function useCamera(_camera : Camera2D) : Void;

    public abstract function usePage(_id : ResourceID) : Void;

    public abstract function useSurface(_id : SurfaceID) : Void;

    public abstract function useUniformBlob(_blob : UniformBlob) : Void;

    public abstract function prepare() : Void;

    public abstract function flush() : Void;

    public abstract function close() : Void;
}
