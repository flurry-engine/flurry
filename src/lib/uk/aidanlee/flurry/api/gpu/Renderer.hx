package uk.aidanlee.flurry.api.gpu;

import hxrx.observer.Observer;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.macros.ApiSelector;

using hxrx.observables.Observables;

abstract class Renderer
{
    final api : RendererBackend;

    final resourceEvents : ResourceEvents;

    public function new(_resourceEvents)
    {
        api            = ApiSelector.getGraphicsApi();
        resourceEvents = _resourceEvents;

        resourceEvents
            .created
            .filter(r -> r is PageResource)
            .map(r -> Std.downcast(r, PageResource))
            .subscribe(new Observer(createTexture, null, null));

        resourceEvents
            .removed
            .filter(r -> r is PageResource)
            .map(r -> Std.downcast(r, PageResource))
            .subscribe(new Observer(createTexture, null, null));
    }

    public abstract function getGraphicsContext() : GraphicsContext;

    public abstract function present() : Void;

    public abstract function createPipeline(_state : PipelineState) : PipelineID;

    public abstract function deletePipeline(_pipeline : PipelineID) : Void;

    abstract function createShader(_resource : Resource) : Void;

    abstract function deleteShader(_resource : Resource) : Void;

    abstract function createTexture(_resource : PageResource) : Void;

    abstract function deleteTexture(_resource : PageResource) : Void;
}