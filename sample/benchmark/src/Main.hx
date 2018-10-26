package;

import snow.App;
import snow.types.Types;
import hxtelemetry.HxTelemetry;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.Event;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.modules.scene.Scene;
import uk.aidanlee.flurry.modules.imgui.ImGuiImpl;
import imgui.ImGui;
import imgui.util.ImVec2;

typedef UserConfig = {};

class Main extends Flurry
{
    var root : Scene;

    var imgui : ImGuiImpl;

    var evMouseMove : Int;

    var evMouseWheel : Int;

    var evTextInput : Int;

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
        imgui = new ImGuiImpl(app, renderer.backend, resources.get('std-shader-textured.json', ShaderResource));

        root = new SampleScene('root', app, null, renderer, resources, events);
        root.resumeOnCreation = true;
        root.create();

        evMouseMove  = events.listen(Event.MouseMove , onMouseMove);
        evMouseWheel = events.listen(Event.MouseWheel, onMouseWheel);
        evTextInput  = events.listen(Event.TextInput , onTextInput);
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
        events.unlisten(evMouseMove);
        events.unlisten(evMouseWheel);
        events.unlisten(evTextInput);

        imgui.dispose();
    }

    function onMouseMove(_event : InputEventMouseMove)
    {
        imgui.onMouseMove(_event.x, _event.y);
    }

    function onMouseWheel(_event : InputEventMouseWheel)
    {
        imgui.onMouseWheel(_event.yWheelChange);
    }

    function onTextInput(_event : InputEventTextInput)
    {
        imgui.onTextInput(_event.text);
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