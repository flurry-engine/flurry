package uk.aidanlee.flurry;

import snow.App;
import snow.api.Debug.log;
import snow.types.Types.AppConfig;
import snow.types.Types.WindowEventType;
import snow.types.Types.SystemEvent;
import uk.aidanlee.flurry.api.CoreEvents;
import uk.aidanlee.flurry.api.EventBus;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.display.Display;
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
    public var flurryConfig (default, null) : FlurryConfig;

    /**
     * The rendering backend of the engine.
     */
    public var renderer (default, null) : Renderer;

    /**
     * The main resource system of the engine.
     */
    public var resources (default, null) : ResourceSystem;

    /**
     * Manages the state of the keyboard, mouse, game gamepads.
     */
    public var input (default, null) : Input;

    /**
     * Manages the programs window and allows access to the mouse coordinates.
     */
    public var display (default, null) : Display;

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
            maxUnchangingIndices  : flurryConfig.renderer.unchangingIndices,
            maxDynamicIndices     : flurryConfig.renderer.dynamicIndices,
            backend : { bindless : false }
        });

        // Pass the renderer backend to the resource system so GPU resources (textures, shaders) can be automatically managed.
        // When loading and freeing parcels the needed GPU resources can then be created and destroyed as and when needed.
        resources = new ResourceSystem(events);

        input   = new Input(events);
        display = new Display(events, flurryConfig);

        // Load the default parcel, this may contain the standard assets or user defined assets.
        // Once it has loaded the overridable onReady function is called.
        resources.createParcel('preload', flurryConfig.resources.preload, function(_) {
            loaded = true;

            onReady();

            // Once the preload resource have been loaded fire the ready event after the engine callback.
            events.fire(Ready);

        }, null, function(_error : String) {
            trace('Error loading preload parcel : $_error');
        }).load();

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
        
        input.update();

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

        // Post-draw

        if (loaded)
        {
            onPostUpdate();

            events.fire(PostUpdate);
        }

        renderer.postRender();

        hxt.advance_frame();
    }

    override final function ondestroy()
    {
        events.fire(Shutdown);

        onShutdown();

        resources.free('preload');
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
