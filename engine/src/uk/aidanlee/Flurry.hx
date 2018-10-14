package uk.aidanlee;

import snow.App;
import snow.api.Emitter;
import snow.api.Debug.log;
import snow.types.Types.AppConfig;
import snow.types.Types.GamepadDeviceEventType;
import snow.types.Types.TextEventType;
import snow.types.Types.ModState;
import snow.types.Types.WindowEventType;
import snow.types.Types.SystemEvent;
import uk.aidanlee.gpu.Renderer;
import uk.aidanlee.gpu.imgui.ImGuiImpl;
import uk.aidanlee.resources.ResourceSystem;
import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.scene.Scene;

class Flurry extends App
{
    var flurryConfig : FlurryConfig;

    var events : Emitter<Int>;

    var renderer : Renderer;

    var resources : ResourceSystem;

    var imgui : ImGuiImpl;

    var root : Scene;

    var loaded : Bool;

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
        events = new Emitter();
        
        // Setup the renderer.
        renderer = new Renderer({

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
        resources = new ResourceSystem(renderer.backend);

        // Load the default parcel, this may contain the standard assets or user defined assets.
        // Once it has loaded the overridable onReady function is called.
        resources.createParcel('preload', flurryConfig.resources.preload, function(_) {
            imgui  = new ImGuiImpl(app, renderer.backend, resources.get('assets/shaders/textured.json', ShaderResource));
            loaded = true;

            onReady();
        }).load();
    }
    
    override final function update(_dt : Float)
    {
        // The resource system needs to be called periodically to process thread events.
        // If this is not called the resources loaded on separate threads won't be registered and parcel callbacks won't be invoked.
        resources.update();

        if (loaded)
        {
            onPreUpdate();
        }

        // Pre-draw
        renderer.clear();
        renderer.preRender();

        // Our game specific logic, only do it if our default parcel has loaded.
        if (loaded)
        {
            imgui.newFrame();

            onUpdate(_dt);
        }

        // Render and present
        renderer.render();

        if (loaded)
        {
            onPostUpdate();            

            imgui.render();
        }

        // Post-draw
        // The window_swap is only needed for GL renderers with snow.
        renderer.postRender();
        if (renderer.api != DX11)
        {
            app.runtime.window_swap();
        }
    }

    override final function ondestroy()
    {
        root.remove();

        imgui.dispose();

        resources.free('preload');

        onShutdown();
    }

    override function onevent(_event : SystemEvent)
    {
        if (_event.window != null)
        {
            if (_event.window.type == WindowEventType.we_resized)
            {
                renderer.resize(_event.window.x, _event.window.y);
            }
        }
    }

    override function onkeyup(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState, _timestamp : Float, windowID : Int)
    {
        if (!loaded) return;

        root.keyUp(_keycode, _scancode, _repeat, _mod);
    }

    override function onkeydown(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState, _timestamp : Float, windowID : Int)
    {
        if (!loaded) return;

        root.keyDown(_keycode, _scancode, _repeat, _mod);
    }

    override function ontextinput(_text : String, _start : Int, _length : Int, _type : TextEventType, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        root.textInput(_text, _start, _length, _type);

        imgui.onTextInput(_text);
    }

    override function onmouseup(_x : Int, _y : Int, _button : Int, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        root.mouseUp(_x, _y, _button);
    }

    override function onmousedown(_x : Int, _y : Int, _button : Int, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        root.mouseDown(_x, _y, _button);
    }

    override function onmousemove(_x : Int, _y : Int, _xRel : Int, _yRel : Int, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        root.mouseMove(_x, _y, _xRel, _yRel);

        imgui.onMouseMove(_x, _y);
    }

    override function onmousewheel(_x : Float, _y : Float, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        root.mouseWheel(_x, _y);

        imgui.onMouseWheel(_y);
    }

    override function ongamepadup(_gamepad : Int, _button : Int, _value : Float, _timestamp : Float)
    {
        if (!loaded) return;

        root.gamepadUp(_gamepad, _button, _value);
    }

    override function ongamepaddown(_gamepad : Int, _button : Int, _value : Float, _timestamp : Float)
    {
        if (!loaded) return;

        root.gamepadDown(_gamepad, _button, _value);
    }

    override function ongamepadaxis(_gamepad : Int, _axis : Int, _value : Float, _timestamp : Float)
    {
        if (!loaded) return;

        root.gamepadAxis(_gamepad, _axis, _value);
    }

    override function ongamepaddevice(_gamepad : Int, _id : String, _type : GamepadDeviceEventType, _timestamp : Float)
    {
        if (!loaded) return;
        
        root.gamepadDevice(_gamepad, _id, _type);
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
