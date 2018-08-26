package uk.aidanlee.gpu;

import haxe.ds.ArraySort;
import uk.aidanlee.gpu.batcher.Batcher;
import uk.aidanlee.gpu.backend.IRendererBackend;
import uk.aidanlee.gpu.backend.WebGLBackend;
import uk.aidanlee.gpu.backend.NullBackend;
#if cpp
import uk.aidanlee.gpu.backend.GL45Backend;
#end
#if windows
import uk.aidanlee.gpu.backend.DX11Backend;
#end

enum RequestedBackend {
    WEBGL;
    GL45;
    DX11;
    NULL;
}

/**
 * Options provided to the renderer on creation.
 */
typedef RendererOptions = {
    /**
     * The backend graphics api to use.
     */
    var api : RequestedBackend;

    /**
     * The initial width of the screen.
     */
    var width : Int;

    /**
     * The initial height of the screen.
     */
    var height : Int;

    /**
     * The DPI of the screen.
     */
    var dpi : Float;

    /**
     * Maximum number of unchanging vertices allowed in the unchanging vertex buffer.
     */
    var maxUnchangingVertices : Int;

    /**
     * Maximum number of dynamic vertices allowed in the dynamic vertex buffer.
     */
    var maxDynamicVertices : Int;

    /**
     * Optional settings for the chosen api backend.
     */
    var ?backend : Dynamic;
}

class Renderer
{
    /**
     * Batcher manager, responsible for creating, deleteing, and sorting batchers.
     */
    public final batchers : Array<Batcher>;

    /**
     * Holds the global render state.
     */
    public final backend : IRendererBackend;

    /**
     * Class which will store information about the previous frame.
     */
    public final stats : RendererStats;

    inline public function new(_options : RendererOptions)
    {
        batchers = [];
        stats    = new RendererStats();

        switch (_options.api) {
            #if cpp
            case GL45 : backend = new GL45Backend(this, _options);
            #end

            #if windows
            case DX11 : backend = new DX11Backend(this, _options);
            #end

            case WEBGL : backend = new WebGLBackend(this, _options);
            default    : backend = new NullBackend();
        }
    }

    inline public function preRender()
    {
        backend.preDraw();

        stats.reset();
    }

    /**
     * Sort and draw all the batchers.
     */
    inline public function render()
    {
        if (batchers.length <= 0) return;

        ArraySort.sort(batchers, sortBatchers);

        stats.totalBatchers += batchers.length;

        for (batcher in batchers)
        {
            stats.totalGeometry += batcher.geometry.length;

            // Batch the geometry and send it to the backend for drawing.
            backend.draw(batcher.vertexBuffer, batcher.batch(), false);
        }
    }

    inline public function postRender()
    {
        backend.postDraw();
    }

    /**
     * Clears the display.
     */
    inline public function clear()
    {
        backend.clear();
    }

    /**
     * Resize the renderer.
     * @param _width  Renderer new width.
     * @param _height Renderer new height.
     */
    inline public function resize(_width : Int, _height : Int)
    {
        backend.resize(_width, _height);
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
            if (_a.target.targetID < _b.target.targetID) return -1;
            if (_a.target.targetID > _b.target.targetID) return  1;
        }
        {
            if (_a.target != null && _b.target == null) return  1;
            if (_a.target == null && _b.target != null) return -1;
        }

        // Then depth
        if (_a.depth < _b.depth) return -1;
        if (_a.depth > _b.depth) return  1;

        // Lastly shader
        if (_a.shader.shaderID < _b.shader.shaderID) return -1;
        if (_a.shader.shaderID > _b.shader.shaderID) return  1;

        return 0;
    }
}
