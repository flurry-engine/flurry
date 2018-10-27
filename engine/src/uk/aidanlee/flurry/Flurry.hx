package uk.aidanlee.flurry;

import snow.App;
import snow.api.Debug.log;
import snow.types.Types.AppConfig;
import snow.types.Types.GamepadDeviceEventType;
import snow.types.Types.TextEventType;
import snow.types.Types.ModState;
import snow.types.Types.WindowEventType;
import snow.types.Types.SystemEvent;
import uk.aidanlee.flurry.api.Event;
import uk.aidanlee.flurry.api.EventBus;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import hxtelemetry.HxTelemetry;

class Flurry extends App
{
    var flurryConfig : FlurryConfig;

    var events : EventBus;

    var renderer : Renderer;

    var resources : ResourceSystem;

    var loaded : Bool;

    var hxt : HxTelemetry;

    public function new()
    {
        //
    }

    // Overriding snow functions to setup the engine.

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

        // Core 3.2 is the minimum required version.
        // Many graphics stacks don't support compatibility profiles and core 3.2 is supported pretty much everywhere by now.
        _config.render.opengl.major   = 3;
        _config.render.opengl.minor   = 2;
        _config.render.opengl.profile = core;

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
        app.runtime.auto_swap = false;

        // Create a new events emitter for the engine components to communicate.
        events = new EventBus();
        
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
                bindless : sdl.SDL.GL_ExtensionSupported('GL_ARB_bindless_texture'),

                // The DX11 backend needs to know the games window so it can fetch the HWND for the DXGI swapchain.
                window : app.runtime.window
            }
        });

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
        if (renderer.api != DX11)
        {
            app.runtime.window_swap();
        }

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

    override final function onkeyup(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState, _timestamp : Float, windowID : Int)
    {
        if (!loaded) return;
        
        events.fire(KeyUp, new InputEventKeyUp(_keycode, _scancode, _repeat, _mod));
    }

    override final function onkeydown(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState, _timestamp : Float, windowID : Int)
    {
        if (!loaded) return;

        events.fire(KeyDown, new InputEventKeyDown(_keycode, _scancode, _repeat, _mod));
    }

    override final function ontextinput(_text : String, _start : Int, _length : Int, _type : TextEventType, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        events.fire(TextInput, new InputEventTextInput(_text, _start, _length, _type));
    }

    override final function onmouseup(_x : Int, _y : Int, _button : Int, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        events.fire(MouseUp, new InputEventMouseUp(_x, _y, _button));
    }

    override final function onmousedown(_x : Int, _y : Int, _button : Int, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        events.fire(MouseDown, new InputEventMouseDown(_x, _y, _button));
    }

    override final function onmousemove(_x : Int, _y : Int, _xRel : Int, _yRel : Int, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        events.fire(MouseMove, new InputEventMouseMove(_x, _y, _xRel, _yRel));
    }

    override final function onmousewheel(_x : Float, _y : Float, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        events.fire(MouseWheel, new InputEventMouseWheel(_x, _y));
    }

    override final function ongamepadup(_gamepad : Int, _button : Int, _value : Float, _timestamp : Float)
    {
        if (!loaded) return;

        events.fire(GamepadUp, new InputEventGamepadUp(_gamepad, _button, _value));
    }

    override final function ongamepaddown(_gamepad : Int, _button : Int, _value : Float, _timestamp : Float)
    {
        if (!loaded) return;

        events.fire(GamepadDown, new InputEventGamepadDown(_gamepad, _button, _value));
    }

    override final function ongamepadaxis(_gamepad : Int, _axis : Int, _value : Float, _timestamp : Float)
    {
        if (!loaded) return;

        events.fire(GamepadAxis, new InputEventGamepadAxis(_gamepad, _axis, _value));
    }

    override final function ongamepaddevice(_gamepad : Int, _id : String, _type : GamepadDeviceEventType, _timestamp : Float)
    {
        if (!loaded) return;

        events.fire(GamepadDevice, new InputEventGamepadDevice(_gamepad, _id, _type));
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
