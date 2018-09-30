package;

import snow.App;
import snow.types.Types;
import hxtelemetry.HxTelemetry;
import uk.aidanlee.gpu.Renderer;
import uk.aidanlee.gpu.imgui.ImGuiImpl;
import uk.aidanlee.resources.ResourceSystem;
import uk.aidanlee.resources.Resource;
import uk.aidanlee.scene.Scene;
import imgui.ImGui;
import imgui.util.ImVec2;

typedef UserConfig = {};

class Main extends App
{
    /**
     * Haxe telemetry instance. Useful for profiling the game.
     * TODO : ifdef this behind some compile time flag so release builds won't include it.
     */
    var telemetry : HxTelemetry;

    /**
     * Games renderer.
     */
    var renderer : Renderer;

    /**
     * Games main resource system.
     * Users can create more of them if they wish but are responsible for managing them themselves.
     */
    var resources : ResourceSystem;

    /**
     * ImGui implementation. Allows for quick debug menus on native targets.
     * TODO : ifdef imgui stuff behind a cpp check, or finally get around to creating emscripten bindings for imgui and a wrangler lib.
     */
    var imgui : ImGuiImpl;

    /**
     * If this engines default assets have loaded.
     */
    var loaded : Bool;

    /**
     * Root scene node.
     */
    var root : Scene;

    public function new() {}

    override function config(_config : AppConfig) : AppConfig
    {
        _config.window.title            = 'gpu';
        _config.window.width            = 1600;
        _config.window.height           = 900;
        _config.window.background_sleep = null;

        // Core 3.2 is the minimum required version.
        // Many graphics stacks don't support compatibility profiles and core 3.2 is supported pretty much everywhere by now.
        _config.render.opengl.major = 3;
        _config.render.opengl.minor = 2;
        _config.render.opengl.profile = core;

        return _config;
    }

    /**
     * Once snow is ready we can create our engine instances and load a parcel with some default assets.
     */
    override function ready()
    {
        loaded    = false;
        telemetry = new HxTelemetry();

        // Setup snow timestep.
        // Fixed dt of 16.66
        fixed_timestep = true;
        update_rate    = 1 / 60;

        // Disable auto swapping. We will swap ourselves if the renderer backend requires it.
        app.runtime.auto_swap = false;
        
        // Setup the renderer.
        renderer = new Renderer({

            // The api you choose changes what shaders you need to provide
            // Possible APIs are WEBGL, GL45, DX11, and NULL
            api    : WEBGL,
            width  : app.runtime.window_width(),
            height : app.runtime.window_height(),
            dpi    : app.runtime.window_device_pixel_ratio(),
            maxUnchangingVertices :  100000,
            maxDynamicVertices    : 1000000,
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

        // Load a pre-packed parcel containing our shader and two images.
        // See the parcel tool for creating pre-packed parcels.
        resources.createParcel('default', { parcels : [ 'assets/parcels/sample.parcel' ] }, onLoaded).load();

        // Setup a default root scene, in the future users will specify their root scene.
        root = new SampleScene('root', app, null, renderer, resources, null);
    }

    /**
     * Simulate all of the engines components.
     * @param _dt 
     */
    override function update(_dt : Float)
    {
        // The resource system needs to be called periodically to process thread events.
        // If this is not called the resources loaded on separate threads won't be registered and parcel callbacks won't be invoked.
        resources.update();

        // Pre-draw
        renderer.clear();
        renderer.preRender();

        // Our game specific logic, only do it if our default parcel has loaded.
        if (loaded)
        {
            imgui.newFrame();

            root.onUpdate(_dt);
        }

        // Render and present
        renderer.render();

        if (loaded)
        {
            uiShowRenderStats();
            imgui.render();
        }

        // Post-draw
        // The window_swap is only needed for GL renderers with snow.
        // If using DX11 comment out that line else GL will render over DX.
        renderer.postRender();
        if (renderer.api != DX11)
        {
            app.runtime.window_swap();
        }

        telemetry.advance_frame();
    }

    /**
     * On shutdown remove the default parcel to free resources.
     */
    override function ondestroy()
    {
        root.onLeave(null);
        root.onRemoved();

        imgui.dispose();

        resources.free('default');
    }

    // #region event functions.

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
        root.onKeyUp(_keycode, _scancode, _repeat, _mod);
    }

    override function onkeydown(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState, _timestamp : Float, windowID : Int)
    {
        root.onKeyDown(_keycode, _scancode, _repeat, _mod);
    }

    override function ontextinput(_text : String, _start : Int, _length : Int, _type : TextEventType, _timestamp : Float, _windowID : Int)
    {
        root.onTextInput(_text, _start, _length, _type);

        imgui.onTextInput(_text);
    }

    override function onmouseup(_x : Int, _y : Int, _button : Int, _timestamp : Float, _windowID : Int)
    {
        root.onMouseUp(_x, _y, _button);
    }

    override function onmousedown(_x : Int, _y : Int, _button : Int, _timestamp : Float, _windowID : Int)
    {
        root.onMouseDown(_x, _y, _button);
    }

    override function onmousemove(_x : Int, _y : Int, _xRel : Int, _yRel : Int, _timestamp : Float, _windowID : Int)
    {
        root.onMouseMove(_x, _y, _xRel, _yRel);

        imgui.onMouseMove(_x, _y);
    }

    override function onmousewheel(_x : Float, _y : Float, _timestamp : Float, _windowID : Int)
    {
        root.onMouseWheel(_x, _y);

        imgui.onMouseWheel(_y);
    }

    override function ongamepadup(_gamepad : Int, _button : Int, _value : Float, _timestamp : Float)
    {
        root.onGamepadUp(_gamepad, _button, _value);
    }

    override function ongamepaddown(_gamepad : Int, _button : Int, _value : Float, _timestamp : Float)
    {
        root.onGamepadDown(_gamepad, _button, _value);
    }

    override function ongamepadaxis(_gamepad : Int, _axis : Int, _value : Float, _timestamp : Float)
    {
        root.onGamepadAxis(_gamepad, _axis, _value);
    }

    override function ongamepaddevice(_gamepad : Int, _id : String, _type : GamepadDeviceEventType, _timestamp : Float)
    {
        root.onGamepadDevice(_gamepad, _id, _type);
    }

    // #endregion

    /**
     * Once the default assets have been loaded create our imgui helper and kick start our root scene.
     * @param _resources Resources loaded.
     */
    function onLoaded(_resources : Array<Resource>)
    {
        imgui  = new ImGuiImpl(app, cast renderer.backend, resources.get('assets/shaders/textured.json', ShaderResource));
        loaded = true;

        root.onCreated();
        root.onEnter(null);
    }

    /**
     * Global ImGui window to display render stats.
     */
    function uiShowRenderStats()
    {
        var distance       = 10;
        var windowPos      = ImVec2.create(ImGui.getIO().displaySize.x - distance, distance);
        var windowPosPivot = ImVec2.create(1, 0);

        ImGui.setNextWindowPos(windowPos, ImGuiCond.Always, windowPosPivot);
        ImGui.setNextWindowBgAlpha(0.3);
        if (ImGui.begin('Render Stats', NoMove | NoTitleBar | NoResize | AlwaysAutoResize | NoSavedSettings | NoFocusOnAppearing | NoNav))
        {
            ImGui.text('total batchers   ${renderer.stats.totalBatchers}');
            ImGui.text('total geometry   ${renderer.stats.totalGeometry}');
            ImGui.text('total vertices   ${renderer.stats.totalVertices}');
            ImGui.text('dynamic draws    ${renderer.stats.dynamicDraws}');
            ImGui.text('unchanging draws ${renderer.stats.unchangingDraws}');

            ImGui.text('');
            ImGui.text('state changes');
            ImGui.separator();

            ImGui.text('target           ${renderer.stats.targetSwaps}');
            ImGui.text('shader           ${renderer.stats.shaderSwaps}');
            ImGui.text('texture          ${renderer.stats.textureSwaps}');
            ImGui.text('viewport         ${renderer.stats.viewportSwaps}');
            ImGui.text('blend            ${renderer.stats.blendSwaps}');
            ImGui.text('scissor          ${renderer.stats.scissorSwaps}');
        }

        ImGui.end();
    }
}