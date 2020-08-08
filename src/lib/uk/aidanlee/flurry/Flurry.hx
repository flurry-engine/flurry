package uk.aidanlee.flurry;

import rx.schedulers.MakeScheduler;
import uk.aidanlee.flurry.api.io.IIO;
import uk.aidanlee.flurry.api.io.FileSystemIO;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.schedulers.ThreadPoolScheduler;
import uk.aidanlee.flurry.api.schedulers.MainThreadScheduler;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;

using Safety;
using rx.Observable;

class Flurry
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
    final mainThreadScheduler : MakeScheduler;

    /**
     * Thread pool backed scheduler.
     */
    final taskThreadScheduler : MakeScheduler;

    public function new()
    {
        events              = new FlurryEvents();
        mainThreadScheduler = MainThreadScheduler.current;
        taskThreadScheduler = ThreadPoolScheduler.current;
    }

    public final function config()
    {
        flurryConfig = onConfig(new FlurryConfig());
    }

    public final function ready()
    {
        loaded = false;
        
        fileSystem = new FileSystem();
        renderer   = new Renderer(events.resource, events.display, flurryConfig.window, flurryConfig.renderer);
        resources  = new ResourceSystem(events.resource, fileSystem, taskThreadScheduler, mainThreadScheduler);
        input      = new Input(events.input);
        display    = new Display(events.display, events.input, flurryConfig);
        io         = new FileSystemIO(flurryConfig.project, fileSystem);

        if (flurryConfig.resources.preload != null)
        {
            resources
                .load(flurryConfig.resources.preload)
                .subscribeFunction(onPreloadParcelError, onPreloadParcelComplete);
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

            input.update();
            renderer.queue();

            onPreRender();
            renderer.submit();
            onPostRender();
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

    final function onPreloadParcelError(_error : String)
    {
        trace('Error loading preload parcel : $_error');
    }
}
