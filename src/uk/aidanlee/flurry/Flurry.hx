package uk.aidanlee.flurry;

import uk.aidanlee.flurry.api.schedulers.CurrentThreadScheduler;
import rx.disposables.ISubscription;
import hx.concurrent.collection.SynchronizedArray;
import rx.Unit;
import rx.Subject;
import rx.subjects.Replay;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import sys.io.abstractions.IFileSystem;
import sys.io.abstractions.concrete.FileSystem;

using rx.Observable;
using Safety;

class Flurry
{
    /**
     * Thread safe array to place functions into.
     * All functions in this array are ran at the beginning of every tick.
     */
    public final dispatch : SynchronizedArray<()->Void>;

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
    public var loaded (default, null) : Bool;

    var preloadSubscription : Null<ISubscription>;

    public function new()
    {
        dispatch = new SynchronizedArray();
        events   = new FlurryEvents();
    }

    public final function config()
    {
        flurryConfig = onConfig(new FlurryConfig());
    }

    public final function ready()
    {
        loaded = false;
        
        // Setup core api components
        fileSystem = new FileSystem();
        renderer   = new Renderer(events.resource, events.display, flurryConfig.window, flurryConfig.renderer);
        resources  = new ResourceSystem(events.resource, fileSystem, CurrentThreadScheduler.current, CurrentThreadScheduler.current);
        input      = new Input(events.input);
        display    = new Display(events.display, events.input, flurryConfig);

        if (flurryConfig.resources.preload != null)
        {
            preloadSubscription = resources
                .load(flurryConfig.resources.preload)
                .subscribeFunction(onPreloadParcelError, onPreloadParcelComplete);
        }
        else
        {
            onPreloadParcelComplete();
        }

        // Fire the init event once the engine has loaded all its components.
        (cast events.init : Replay<Unit>).onCompleted();
    }

    public final function tick(_dt : Float)
    {
        // Call any main loop functions.
        // We should be able to safely skip the null function check as we already check the size;
        // please don't pass in null functions...
        while (!dispatch.isEmpty())
        {
            dispatch.removeFirst().unsafe()();
        }

        onTick(_dt);
    }
    
    public final function update(_dt : Float)
    {
        if (loaded)
        {
            onPreUpdate();

            (cast events.preUpdate : Subject<Unit>).onNext(unit);
        }

        // Pre-draw
        renderer.preRender();

        // Our game specific logic, only do it if our default parcel has loaded.
        if (loaded)
        {
            onUpdate(_dt);

            (cast events.update : Subject<Float>).onNext(_dt);
        }

        // Render and present
        renderer.render();

        // Post-draw

        if (loaded)
        {
            onPostUpdate();

            input.update();

            (cast events.postUpdate : Subject<Unit>).onNext(unit);
        }

        renderer.postRender();
    }

    public final function shutdown()
    {
        (cast events.preUpdate : Subject<Unit>).onNext(unit);

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

    function onShutdown()
    {
        //
    }

    // Functions internal to flurry's setup

    final function onPreloadParcelComplete()
    {
        loaded = true;

        onReady();

        (cast events.ready : Replay<Unit>).onCompleted();
    }

    final function onPreloadParcelError(_error : String)
    {
        throw 'Error loading preload parcel : $_error';
    }
}
