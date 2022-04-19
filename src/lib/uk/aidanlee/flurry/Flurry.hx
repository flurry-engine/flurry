package uk.aidanlee.flurry;

import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import haxe.Exception;
import hxrx.observer.Observer;
import hxrx.schedulers.IScheduler;
import uk.aidanlee.flurry.api.io.IIO;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.schedulers.ThreadPoolScheduler;
import uk.aidanlee.flurry.api.schedulers.MainThreadScheduler;

using hxrx.observables.Observables;
using Safety;

class Flurry
{
    /**
     * Main events bus, engine components can fire events into this to communicate with each other.
     */
    public final events : FlurryEvents;

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
     * Provides a quick and easy to save and load game related data.
     */
    public var io (default, null) : IIO;

    /**
     * If the preload parcel has been loaded.
     */
    public var loaded (default, null) : Bool;

    /**
     * Scheduler to run functions on the main thread.
     * Every tick the tasks queued in this scheduler are checked to see if its time to be ran.
     */
    final mainThreadScheduler : IScheduler;

    /**
     * Thread pool backed scheduler.
     */
    final taskThreadScheduler : IScheduler;

    public function new(_events, _mainScheduler, _taskScheduler)
    {
        events              = _events;
        mainThreadScheduler = _mainScheduler;
        taskThreadScheduler = _taskScheduler;
    }

    public final function config(_config)
    {
        flurryConfig = onConfig(_config);
    }

    public final function ready(_renderer, _resources, _input, _display, _io)
    {
        loaded = false;

        renderer   = _renderer;
        resources  = _resources;
        input      = _input;
        display    = _display;
        io         = _io;

        if (flurryConfig.resources.preload != null)
        {
            resources
                .load(flurryConfig.resources.preload)
                .subscribeFunction(null, onPreloadParcelError, onPreloadParcelComplete);
        }
        else
        {
            onPreloadParcelComplete();
        }
    }

    public final function tick(_dt : Float)
    {
        (cast mainThreadScheduler : MainThreadScheduler).dispatch();

        onTick(_dt);
    }
    
    public final function update(_dt : Float)
    {
        if (loaded)
        {
            onPreUpdate();

            onUpdate(_dt);

            onPostUpdate();

            onPreRender();

            final ctx = renderer.getGraphicsContext();

            onRender(ctx);
            
            ctx.close();

            onPostRender();

            renderer.present();

            input.update();
        }
    }

    public final function shutdown()
    {
        onShutdown();
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

    function onTick(_dt : Float)
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

    function onPreRender()
    {
        //
    }

    function onRender(_ctx : GraphicsContext)
    {
        //
    }

    function onPostRender()
    {
        //
    }

    function onShutdown()
    {
        //
    }

    // Functions internal to flurry's setup

    final function onPreloadParcelComplete()
    {
        loaded = true;

        onReady();
    }

    final function onPreloadParcelError(_error : Exception)
    {
        throw _error;
    }
}
