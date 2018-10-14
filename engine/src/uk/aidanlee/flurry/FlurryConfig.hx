package uk.aidanlee.flurry;

import uk.aidanlee.flurry.api.resources.Parcel.ParcelList;
import uk.aidanlee.flurry.api.gpu.Renderer.RequestedBackend;

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

private class FlurryWindowConfig
{
    /**
     * If the window should be launched in fullscreen borderless mode. (Defaults false)
     */
    public var fullscreen : Bool;

    /**
     * If the window is resiable by the user. (Defaults true)
     */
    public var resizable : Bool;

    /**
     * If the window should be borderless. (Defaults false)
     */
    public var borderless : Bool;

    /**
     * The initial width of the window.
     */
    public var width : Int;

    /**
     * The initial height of the window.
     */
    public var height : Int;

    /**
     * The title of the window.
     */
    public var title : String;

    /**
     * Create a window config class with the default settings.
     */
    public function new()
    {
        fullscreen = false;
        resizable  = true;
        borderless = false;
        width      = 1280;
        height     = 720;
        title      = "Flurry";
    }
}

private class FlurryRendererConfig
{
    /**
     * Force the renderer to use a specific backend.
     * If left unchanged it will attempt to auto-select the best backend for the platform.
     */
    public var backend : RequestedBackend;

    /**
     * The maximum number of vertices allowed in the dynamic vertex buffer. (Defaults 1000000)
     */
    public var dynamicVertices : Int;

    /**
     * The maximum number of vertices allowed in the unchanging vertex buffer. (Defaults 100000)
     */
    public var unchangingVertices : Int;

    /**
     * The default clear colour used by the renderer.
     */
    public final clearColour : { r : Float, g : Float, b : Float, a : Float };

    /**
     * Creates a new renderer config with the default settings.
     */
    public function new()
    {
        dynamicVertices    = 1000000;
        unchangingVertices = 100000;
        clearColour        = { r : 0.2, g : 0.2, b : 0.2, a : 1.0 };
    }
}

private class FlurryResourceConfig
{
    /**
     * If the standard shader parcel should not be loaded. (Defaults true).
     */
    public var includeStdShaders : Bool;

    /**
     * Any resources placed into this parcel list will be loaded before the Flurry's onReady function is called.
     */
    public final preload : ParcelList;

    /**
     * Create a new resource config with the default settings.
     */
    public function new()
    {
        includeStdShaders = true;
        preload = {
            bytes   : [],
            texts   : [],
            jsons   : [],
            images  : [],
            shaders : [],
            parcels : []
        };
    }
}
