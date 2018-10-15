package;

import snow.App;
import snow.types.Types;
import hxtelemetry.HxTelemetry;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.modules.scene.Scene;
import uk.aidanlee.flurry.modules.imgui.ImGuiImpl;
import imgui.ImGui;
import imgui.util.ImVec2;

typedef UserConfig = {};

class Main extends Flurry
{
    var imgui : ImGuiImpl;

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = GL45;

        _config.resources.preload.parcels.push('assets/parcels/sample.parcel');

        return _config;
    }

    override function onReady()
    {
        imgui = new ImGuiImpl(app, renderer.backend, resources.get('assets/shaders/textured.json', ShaderResource));

        root = new SampleScene('root', app, null, renderer, resources, events);
        root.resumeOnCreation = true;
        root.create();
    }

    override function onPreUpdate()
    {
        imgui.newFrame();
    }

    override function onUpdate(_dt : Float)
    {
        root.update(_dt);
    }

    override function onPostUpdate()
    {
        uiShowRenderStats();
        
        imgui.render();
    }

    override function onShutdown()
    {
        imgui.dispose();
    }

    // We need to override the flurry / snow events for imgui to hook into them

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

    override function ontextinput(_text : String, _start : Int, _length : Int, _type : TextEventType, _timestamp : Float, _windowID : Int)
    {
        if (!loaded) return;

        root.textInput(_text, _start, _length, _type);

        imgui.onTextInput(_text);
    }

    // Draw some stats about the renderer.

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