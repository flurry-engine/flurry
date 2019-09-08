package uk.aidanlee.flurry.api.gpu;

import haxe.Exception;
import haxe.ds.ArraySort;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.backend.IRendererBackend;
import uk.aidanlee.flurry.api.gpu.backend.MockBackend;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.display.DisplayEvents;

class Renderer
{
    /**
     * Holds the global render state.
     */
    public final backend : IRendererBackend;

    /**
     * API backend used by the renderer.
     */
    public final api : RendererBackend;

    /**
     * Class which will store information about the previous frame.
     */
    public final stats : RendererStats;

    /**
     * Batcher manager, responsible for creating, deleteing, and sorting batchers.
     */
    final batchers : Array<Batcher>;

    /**
     * Queue of all draw commands for this frame.
     */
    final queuedCommands : Array<DrawCommand>;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        queuedCommands = [];
        batchers       = [];
        api            = _rendererConfig.backend;
        stats          = new RendererStats();
        backend         = switch api
        {
            #if cpp
                case Ogl4: new uk.aidanlee.flurry.api.gpu.backend.ogl4.OGL4Backend(_resourceEvents, _displayEvents, stats, _windowConfig, _rendererConfig);
                case Ogl3: new uk.aidanlee.flurry.api.gpu.backend.OGL3Backend(_resourceEvents, _displayEvents, stats, _windowConfig, _rendererConfig);

                case Dx11:
                    #if windows
                        new uk.aidanlee.flurry.api.gpu.backend.DX11Backend(_resourceEvents, _displayEvents, stats, _windowConfig, _rendererConfig);
                    #else
                        throw new BackendNotAvailableException(api);
                    #end
            #end

            case Auto:
                #if (cpp && windows)
                    new uk.aidanlee.flurry.api.gpu.backend.DX11Backend(_resourceEvents, _displayEvents, stats, _windowConfig, _rendererConfig);
                #elseif cpp
                    new uk.aidanlee.flurry.api.gpu.backend.OGL3Backend(_resourceEvents, _displayEvents, stats, _windowConfig, _rendererConfig);
                #else
                    new MockBackend(_resourceEvents);
                #end
            case _: new MockBackend(_resourceEvents);
        }
    }

    public function preRender()
    {
        backend.preDraw();

        stats.reset();
    }

    /**
     * Sort and draw all the batchers.
     */
    public function render()
    {
        if (batchers.length <= 0) return;

        ArraySort.sort(batchers, sortBatchers);

        stats.totalBatchers += batchers.length;

        queuedCommands.resize(0);
        for (batcher in batchers)
        {
            batcher.batch(cast queuedCommands);
        }

        backend.uploadGeometryCommands(cast queuedCommands);
        backend.submitCommands(queuedCommands);
    }

    public function postRender()
    {
        backend.postDraw();
    }

    /**
     * Create and return a batcher. The returned batcher is automatically added to the renderer.
     * @param _options Batcher options.
     * @return Batcher
     */
    public function createBatcher(_options : BatcherOptions) : Batcher
    {
        var batcher = new Batcher(_options);

        batchers.push(batcher);

        return batcher;
    }

    /**
     * Add several pre-existing batchers to the renderer.
     * @param _batchers Array of batchers to add.
     */
    public function addBatcher(_batchers : Array<Batcher>)
    {
        for (batcher in _batchers)
        {
            batchers.push(batcher);
        }
    }

    /**
     * Remove several batchers from the renderer.
     * @param _batchers Array of batchers to remove.
     */
    public function removeBatcher(_batchers : Array<Batcher>)
    {
        for (batcher in _batchers)
        {
            batchers.remove(batcher);
        }
    }

    /**
     * Sort the batchers in depth order.
     * @param _a Batcher a
     * @param _b Batcher b
     * @return Int
     */
    function sortBatchers(_a : Batcher, _b : Batcher) : Int
    {
        // Sort by framebuffer
        if (_a.target != null && _b.target != null)
        {
            if (_a.target.id < _b.target.id) return -1;
            if (_a.target.id > _b.target.id) return  1;
        }
        else
        {
            if (_a.target != null && _b.target == null) return -1;
            if (_a.target == null && _b.target != null) return  1;
        }

        // Then depth
        if (_a.depth < _b.depth) return -1;
        if (_a.depth > _b.depth) return  1;

        // Lastly shader
        if (_a.shader.id < _b.shader.id) return -1;
        if (_a.shader.id > _b.shader.id) return  1;

        return 0;
    }
}

class BackendNotAvailableException extends Exception
{
    public function new(_backend : RendererBackend)
    {
        super('$_backend is not available on this platform');
    }
}
