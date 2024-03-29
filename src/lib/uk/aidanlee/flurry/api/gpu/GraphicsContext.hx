package uk.aidanlee.flurry.api.gpu;

import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.shaders.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
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

    public abstract function usePage(_slot : Int, _id : ResourceID, _sampler : SamplerState) : Void;

    public abstract function useSurface(_slot : Int, _id : SurfaceID, _sampler : SamplerState) : Void;

    public abstract function useUniformBlob(_blob : UniformBlob) : Void;

    public abstract function useScissorRegion(_x : Int, _y : Int, _width : Int, _height : Int) : Void;

    public abstract function prepare() : Void;

    public abstract function flush() : Void;

    public abstract function close() : Void;
}
