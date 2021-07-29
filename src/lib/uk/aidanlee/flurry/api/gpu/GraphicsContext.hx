package uk.aidanlee.flurry.api.gpu;

import haxe.io.Output;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.resources.ResourceID;

abstract class GraphicsContext
{
    public var vtxOutput (get, never) : Output;

    public var idxOutput (get, never) : Output;

    abstract function get_vtxOutput() : Output;

    abstract function get_idxOutput() : Output;

    public abstract function usePipeline(_id : PipelineID) : Void;

    public abstract function useCamera(_camera : Camera2D) : Void;

    public abstract function usePage(_id : ResourceID) : Void;

    public abstract function useUniformBlob(_blob : UniformBlob) : Void;

    public abstract function prepare() : Void;

    public abstract function flush() : Void;

    public abstract function close() : Void;
}
