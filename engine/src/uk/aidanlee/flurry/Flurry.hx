package uk.aidanlee.flurry;

import snow.App;
import snow.api.Debug.log;
import snow.types.Types.AppConfig;
import snow.types.Types.WindowEventType;
import snow.types.Types.SystemEvent;
import uk.aidanlee.flurry.api.Event;
import uk.aidanlee.flurry.api.EventBus;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import hxtelemetry.HxTelemetry;

class Flurry extends App
{
    /**
     * Main events bus, engine components can fire events into this to communicate with each other.
     */
    public final events : EventBus;

    /**
     * User config file.
     */
    var flurryConfig : FlurryConfig;

    /**
     * The rendering backend of the engine.
     */
    var renderer : Renderer;

    /**
     * The main resource system of the engine.
     */
    var resources : ResourceSystem;

    /**
     * If the preload parcel has been loaded.
     */
    var loaded : Bool;

    /**
     * Haxe telemetry object.
     */
    var hxt : HxTelemetry;

    public function new()
    {
        events = new EventBus();
    }

    /**
     * If the preload parcel has been used.
     * Mostly used by the runtime to decide if input and window events should be fired.
     * @return Bool
     */
    public function isLoaded() : Bool
    {
        return loaded;
    }

    override final function config(_config : AppConfig) : AppConfig
    {
        flurryConfig = onConfig(new FlurryConfig());

        // Copy the window settings over to snow.
        _config.window.fullscreen       = flurryConfig.window.fullscreen;
        _config.window.borderless       = flurryConfig.window.borderless;
        _config.window.resizable        = flurryConfig.window.resizable;
        _config.window.width            = flurryConfig.window.width;
        _config.window.height           = flurryConfig.window.height;
        _config.window.title            = flurryConfig.window.title;
        _config.window.background_sleep = 0;

        if (flurryConfig.resources.includeStdShaders)
        {
            log('TODO : Load a default shader parcel');
        }

        return _config;
    }

    override final function ready()
    {
        loaded = false;

        // Setup snow timestep.
        // Fixed dt of 16.66
        fixed_timestep = true;
        update_rate    = 1 / 60;

        // Disable auto swapping. We will swap ourselves if the renderer backend requires it.
        // app.runtime.auto_swap = false;

        trace('creating the renderer');
        
        // Setup the renderer.
        renderer = new Renderer(events, {

            // The api you choose changes what shaders you need to provide
            // Possible APIs are WEBGL, GL45, DX11, and NULL
            api    : flurryConfig.renderer.backend,
            width  : flurryConfig.window.width,
            height : flurryConfig.window.height,
            dpi    : 1,
            maxUnchangingVertices : flurryConfig.renderer.unchangingVertices,
            maxDynamicVertices    : flurryConfig.renderer.dynamicVertices,
            backend : {

                // This tells the GL4.5 backend if we can use bindless textures
                bindless : true //sdl.SDL.GL_ExtensionSupported('GL_ARB_bindless_texture'),

                // The DX11 backend needs to know the games window so it can fetch the HWND for the DXGI swapchain.
                // window : app.runtime.window
            }
        });

        trace('creating the resource system');

        // Pass the renderer backend to the resource system so GPU resources (textures, shaders) can be automatically managed.
        // When loading and freeing parcels the needed GPU resources can then be created and destroyed as and when needed.
        resources = new ResourceSystem(events);

        // Load the default parcel, this may contain the standard assets or user defined assets.
        // Once it has loaded the overridable onReady function is called.
        resources.createParcel('preload', flurryConfig.resources.preload, function(_) {
            loaded = true;

            onReady();

            // Once the preload resource have been loaded fire the ready event after the engine callback.
            events.fire(Ready);

        }, null, _e -> trace('Error loading preload parcel : ${_e}')).load();

        // Fire the init event once the engine has loaded all its components.
        events.fire(Init);

        var cfg = new Config();
        cfg.app_name    = 'flurry';
        cfg.profiler    = true;
        cfg.allocations = true;
        cfg.trace       = true;
        cfg.cpu_usage   = true;
        cfg.activity_descriptors = [ { name : '.rendering', description : 'Time Spent Drawing', color : 0xE91E63 } ];
        hxt = new HxTelemetry(cfg);
    }
    
    override final function update(_dt : Float)
    {
        // The resource system needs to be called periodically to process thread events.
        // If this is not called the resources loaded on separate threads won't be registered and parcel callbacks won't be invoked.
        resources.update();

        if (loaded)
        {
            onPreUpdate();

            events.fire(PreUpdate);
        }

        // Pre-draw
        renderer.clear();
        renderer.preRender();

        // Our game specific logic, only do it if our default parcel has loaded.
        if (loaded)
        {
            onUpdate(_dt);

            events.fire(Update);
        }

        // Render and present
        hxt.start_timing('.rendering');
        renderer.render();
        hxt.end_timing('.rendering');

        if (loaded)
        {
            onPostUpdate();

            events.fire(PostUpdate);
        }

        // Post-draw
        // The window_swap is only needed for GL renderers with snow.
        renderer.postRender();

        hxt.advance_frame();
    }

    override final function ondestroy()
    {
        events.fire(Shutdown);

        onShutdown();

        resources.free('preload');
    }

    override final function onevent(_event : SystemEvent)
    {
        if (_event.window != null)
        {
            if (_event.window.type == WindowEventType.we_resized)
            {
                renderer.resize(_event.window.x, _event.window.y);
            }
        }
    }

    // Flurry functions the user can override.

    function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        return _config;
    }

    function onReady()
    {
        //
    }

    function onPreUpdate()
    {
        //
    }

    function onUpdate(_dt : Float)
    {
        //
    }

    function onPostUpdate()
    {
        //
    }

    function onShutdown()
    {
        //
    }

    // Functions internal to flurry's setup
}
