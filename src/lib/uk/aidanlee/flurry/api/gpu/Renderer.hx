package uk.aidanlee.flurry.api.gpu;

import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.macros.ApiSelector;

using hxrx.observables.Observables;

abstract class Renderer
{
    public final api : RendererBackend;

    final resourceEvents : ResourceEvents;

    public function new(_resourceEvents)
    {
        api            = getGraphicsApi();
        resourceEvents = _resourceEvents;

        resourceEvents
            .created
            .filter(r -> r is PageResource)
            .map(r -> Std.downcast(r, PageResource))
            .subscribeFunction(createTexture);

        resourceEvents
            .removed
            .filter(r -> r is PageResource)
            .map(r -> Std.downcast(r, PageResource))
            .subscribeFunction(createTexture);
    }

    public abstract function getGraphicsContext() : GraphicsContext;

    public abstract function present() : Void;

    public abstract function createPipeline(_state : PipelineState) : PipelineID;

    public abstract function deletePipeline(_pipeline : PipelineID) : Void;

    public abstract function createSurface(_width : Int, _height : Int) : SurfaceID;

    public abstract function deleteSurface(_id : SurfaceID) : Void;

    abstract function createShader(_resource : Resource) : Void;

    abstract function deleteShader(_resource : Resource) : Void;

    abstract function createTexture(_resource : PageResource) : Void;

    abstract function deleteTexture(_resource : PageResource) : Void;
}