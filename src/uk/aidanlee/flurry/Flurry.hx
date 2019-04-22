package uk.aidanlee.flurry;

import snow.App;
import snow.types.Types.AppConfig;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;
import hxtelemetry.HxTelemetry;

class Flurry extends App
{
    /**
     * Main events bus, engine components can fire events into this to communicate with each other.
     */
    public final events : FlurryEvents;

    /**
     * Abstracted access to the devices file system.
     */
    public var fileSystem (default, null) : IFileSystem;

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
        events = new FlurryEvents();
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
            trace('TODO : Load a default shader parcel');
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
        
        // Setup core api components
        fileSystem = new FileSystem();
        renderer   = new Renderer(events.resource, events.display, flurryConfig.window, flurryConfig.renderer);
        resources  = new ResourceSystem(events.resource, fileSystem);
        input      = new Input(events.input);
        display    = new Display(events.display, events.input, flurryConfig);

        // Load the default parcel, this may contain the standard assets or user defined assets.
        // Once it has loaded the overridable onReady function is called.
        resources.createParcel('preload', flurryConfig.resources.preload, onPreloadParcelComplete, null, onPreloadParcelError).load();

        // Fire the init event once the engine has loaded all its components.
        events.init.dispatch();

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

            events.preUpdate.dispatch();
        }

        // Pre-draw
        renderer.clear();
        renderer.preRender();

        // Our game specific logic, only do it if our default parcel has loaded.
        if (loaded)
        {
            onUpdate(_dt);

            events.update.dispatch();
        }

        // Render and present
        hxt.start_timing('.rendering');
        renderer.render();
        hxt.end_timing('.rendering');

        // Post-draw

        if (loaded)
        {
            onPostUpdate();

            events.postUpdate.dispatch();
        }

        renderer.postRender();

        input.update();

        hxt.advance_frame();
    }

    override final function ondestroy()
    {
        events.shutdown.dispatch();

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

    final function onPreloadParcelComplete(_)
    {
        loaded = true;

        onReady();

        events.ready.dispatch();
    }

    final function onPreloadParcelError(_error : String)
    {
        throw 'Error loading preload parcel : $_error';
    }
}
