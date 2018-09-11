package uk.aidanlee.gpu;

import haxe.ds.ArraySort;
import snow.api.buffers.Uint8Array;
import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.resources.Resource.ImageResource;
import uk.aidanlee.gpu.batcher.DrawCommand;
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

    /**
     * Queue of all draw commands for this frame.
     */
    final queuedCommands : Array<DrawCommand>;

    /**
     * API backend used by the renderer.
     */
    final api : RequestedBackend;

    inline public function new(_options : RendererOptions)
    {
        queuedCommands = [];
        batchers = [];
        stats    = new RendererStats();

        switch (_options.api) {
            #if cpp
            case GL45:
                backend = new GL45Backend(this, _options);
                api     = GL45;
            #end

            #if windows
            case DX11:
                backend = new DX11Backend(this, _options);
                api     = DX11;
            #end

            case WEBGL:
                backend = new WebGLBackend(this, _options);
                api     = WEBGL;

            default:
                backend = new NullBackend();
                api     = NULL;
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

        queuedCommands.resize(0);
        for (batcher in batchers)
        {
            batcher.batch(cast queuedCommands);
        }

        backend.uploadGeometryCommands(cast queuedCommands);
        backend.submitCommands(queuedCommands);
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
     * Create a texture.
     * @param _resource Image resource to create a texture from.
     * @return Texture
     */
    public function createTexture(_resource : ImageResource) : Texture
    {
        return backend.createTexture(Uint8Array.fromBuffer(_resource.pixels, 0, _resource.pixels.length), _resource.width, _resource.height);
    }

    /**
     * Create a empty render target.
     * @param _width  Width of the render target.
     * @param _height Height of the render target.
     * @return RenderTexture
     */
    public function createRenderTarget(_width : Int, _height : Int) : RenderTexture
    {
        return backend.createRenderTarget(_width, _height);
    }

    /**
     * Create a shader.
     * @param _resource Shader resource to create the shader from.
     * @return Shader
     */
    public function createShader(_resource : ShaderResource) : Shader
    {
        switch (api) {
            case WEBGL:
                if (_resource.webgl == null)
                {
                    throw '${_resource.id} does not contain a webgl shader';
                }
                return backend.createShader(_resource.webgl.vertex, _resource.webgl.fragment, _resource.layout);
            case GL45:
                if (_resource.gl45 == null)
                {
                    throw '${_resource.id} does not contain a gl45 shader';
                }
                return backend.createShader(_resource.gl45.vertex, _resource.gl45.fragment, _resource.layout);
            case DX11:
                if (_resource.hlsl == null)
                {
                    throw '${_resource.id} does not contain a hlsl shader';
                }
                return backend.createShader(_resource.hlsl.vertex, _resource.hlsl.fragment, _resource.layout);
            case NULL:
                return backend.createShader('', '', { textures : [], blocks : [] });
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
