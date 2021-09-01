package uk.aidanlee.flurry.api.gpu;

import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceState;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.builtin.ShaderResource;
import uk.aidanlee.flurry.api.resources.builtin.DataBlobResource;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

using hxrx.observables.Observables;

abstract class Renderer
{
    final resourceEvents : ResourceEvents;

    public function new(_resourceEvents)
    {
        resourceEvents = _resourceEvents;

        resourceEvents
            .created
            .filter(isPageResource)
            .map(toPageResource)
            .subscribeFunction(createTexture);

        resourceEvents
            .removed
            .filter(isPageResource)
            .map(toResourceID)
            .subscribeFunction(deleteTexture);

        resourceEvents
            .created
            .filter(isShaderResource)
            .map(toShaderResource)
            .subscribeFunction(createShader);

        resourceEvents
            .removed
            .filter(isShaderResource)
            .map(toResourceID)
            .subscribeFunction(deleteShader);
    }

    public abstract function getGraphicsContext() : GraphicsContext;

    public abstract function present() : Void;

    public abstract function createPipeline(_state : PipelineState) : PipelineID;

    public abstract function deletePipeline(_pipeline : PipelineID) : Void;

    public abstract function createSurface(_state : SurfaceState) : SurfaceID;

    public abstract function deleteSurface(_id : SurfaceID) : Void;

    public abstract function updateTexture(_frame : PageFrameResource, _data : ArrayBufferView) : Void;

    abstract function createShader(_resource : DataBlobResource) : Void;

    abstract function deleteShader(_id : ResourceID) : Void;

    abstract function createTexture(_resource : DataBlobResource) : Void;

    abstract function deleteTexture(_id : ResourceID) : Void;

    function isPageResource(_resource : Resource)
    {
        return switch Std.downcast(_resource, DataBlobResource)
        {
            case null: false;
            case blob: blob.resource is PageResource;
        }
    }

    function isShaderResource(_resource : Resource)
    {
        return switch Std.downcast(_resource, DataBlobResource)
        {
            case null: false;
            case blob: blob.resource is ShaderResource;
        }
    }

    function toPageResource(_resource : Resource)
    {
        return (cast _resource : DataBlobResource);
    }

    function toShaderResource(_resource : Resource)
    {
        return (cast _resource : DataBlobResource);
    }

    function toResourceID(_resource : Resource)
    {
        return _resource.id;
    }
}