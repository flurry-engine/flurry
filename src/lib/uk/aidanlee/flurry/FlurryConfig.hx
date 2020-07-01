package uk.aidanlee.flurry;

import uk.aidanlee.flurry.api.maths.Vector4;

class FlurryConfig
{
    /**
     * All the window config options.
     */
    public final window : FlurryWindowConfig;

    /**
     * All the renderer config options.
     */
    public final renderer : FlurryRendererConfig;

    /**
     * All the resource config options.
     */
    public final resources : FlurryResourceConfig;

    public function new()
    {
        window    = new FlurryWindowConfig();
        renderer  = new FlurryRendererConfig();
        resources = new FlurryResourceConfig();
    }
}

class FlurryWindowConfig
{
    /**
     * If the window should be launched in fullscreen borderless mode. (Defaults false)
     */
    public var fullscreen : Bool;

    /**
     * If the window should have vsync applied to it. (Defaults false)
     */
    public var vsync : Bool;

    /**
     * If the window is resiable by the user. (Defaults true)
     */
    public var resizable : Bool;

    /**
     * If the window should be borderless. (Defaults false)
     */
    public var borderless : Bool;

    /**
     * The initial width of the window. (Defaults 1280)
     */
    public var width : Int;

    /**
     * The initial height of the window. (Defaults 720)
     */
    public var height : Int;

    /**
     * The title of the window. (Defaults 'Flurry')
     */
    public var title : String;

    /**
     * Create a window config class with the default settings.
     */
    public function new()
    {
        fullscreen = false;
        vsync      = false;
        resizable  = true;
        borderless = false;
        width      = 1280;
        height     = 720;
        title      = "Flurry";
    }
}

class FlurryRendererConfig
{
    /**
     * Config options for the OpenGL 3 renderer.
     */
    public var ogl3 : FlurryRendererOgl3Config;

    /**
     * Config options for the OpenGL 4 renderer.
     */
    public var ogl4 : FlurryRendererOgl4Config;

    /**
     * Config options for the D3D11 renderer.
     */
    public var dx11 : FlurryRendererDx11Config;

    public function new()
    {
        ogl3    = new FlurryRendererOgl3Config();
        ogl4    = new FlurryRendererOgl4Config();
        dx11    = new FlurryRendererDx11Config();
    }
}

class FlurryRendererOgl3Config
{
    /**
     * Size in bytes of the vertex buffer.
     * Default size is enough to store 100,000 indexed quads vertices.
     */
    public var vertexBufferSize : Int;

    /**
     * Size in bytes of the index buffer.
     * Default size is enough to store 100,000 indexed quads indices.
     */
    public var indexBufferSize : Int;

    /**
     * Size in bytes of the matrix buffer.
     * Default size is enough to store 100,000 mvp matrices (assuming 256 byte ubo alignment).
     */
    public var matrixBufferSize : Int;

    /**
     * Size in bytes of the uniform buffer.
     * Default size is 10Mb.
     */
    public var uniformBufferSize : Int;

    /**
     * The colour clear the backbuffer to at the beginning of each frame.
     */
    public var clearColour : Vector4;

    public function new()
    {
        vertexBufferSize  = 14400000;
        indexBufferSize   = 1200000;
        matrixBufferSize  = 25600000;
        uniformBufferSize = 10000000;
        clearColour       = new Vector4(0.2, 0.2, 0.2, 1.0);
    }
}

class FlurryRendererOgl4Config
{
    /**
     * Size in bytes of the vertex buffer.
     * Default size is enough to store 100,000 indexed quads vertices.
     */
    public var vertexBufferSize : Int;

     /**
      * Size in bytes of the index buffer.
      * Default size is enough to store 100,000 indexed quads indices.
      */
    public var indexBufferSize : Int;
 
     /**
      * Size in bytes of the matrix buffer.
      * Default size is enough to store 100,000 mvp matrices (assuming 256 byte ubo alignment).
      */
    public var matrixBufferSize : Int;
 
     /**
      * Size in bytes of the uniform buffer.
      * Default size is 10Mb.
      */
    public var uniformBufferSize : Int;

    /**
     * Size in bytes of the indirect buffer.
     * Default size is enough to store 100,000 commands for indexed drawing.
     */
    public var indirectBufferSize : Int;

    /**
     * The colour clear the backbuffer to at the beginning of each frame.
     */
    public var clearColour : Vector4;

    /**
     * The amount of buffering to perform on the internal buffers.
     * Defaults to triple buffering.
     */
    public var bufferingCount : Int;

    /**
     * If enabled creates the OpenGL context with the debug flag and listens to debug output.
     * Defaults to false.
     */
    public var enableDebugOutput : Bool;

    public function new()
    {
        vertexBufferSize   = 14400000;
        indexBufferSize    = 1200000;
        matrixBufferSize   = 25600000;
        uniformBufferSize  = 10000000;
        indirectBufferSize = 2000000;
        clearColour        = new Vector4(0.2, 0.2, 0.2, 1.0);
        bufferingCount     = 3;
        enableDebugOutput  = false;
    }
}

class FlurryRendererDx11Config
{
    /**
     * Size in bytes of the vertex buffer.
     * Default size is enough to store 100,000 indexed quads vertices.
     */
    public var vertexBufferSize : Int;

    /**
     * Size in bytes of the index buffer.
     * Default size is enough to store 100,000 indexed quads indices.
     */
    public var indexBufferSize : Int;

    /**
     * Size in bytes of the matrix buffer.
     * Default size is enough to store 100,000 mvp matrices.
     */
    public var matrixBufferSize : Int;
 
    /**
     * Size in bytes of the uniform buffer.
     * Default size is 10Mb.
     */
    public var uniformBufferSize : Int;

    /**
     * The colour clear the backbuffer to at the beginning of each frame.
     */
    public var clearColour : Vector4;

    /**
     * If the ID3D11Device is created in debug mode (requires gpu debugging tools to be installed).
     * Defaults to false;
     */
    public var debugDevice : Bool;

    public function new()
    {
        vertexBufferSize  = 14400000;
        indexBufferSize   = 1200000;
        matrixBufferSize  = 25600000;
        uniformBufferSize = 10000000;
        clearColour       = new Vector4(0.2, 0.2, 0.2, 1.0);
        debugDevice       = false;
    }
}

class FlurryResourceConfig
{
    /**
     * Any resources placed into this parcel list will be loaded before the Flurry's onReady function is called.
     */
    public var preload : Null<Array<String>>;

    /**
     * Create a new resource config with the default settings.
     */
    public function new()
    {
        preload = null;
    }
}
