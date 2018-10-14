package;

import snow.App;
import snow.types.Types;
import hxtelemetry.HxTelemetry;
import uk.aidanlee.Flurry;
import uk.aidanlee.FlurryConfig;
import uk.aidanlee.gpu.Renderer;
import uk.aidanlee.gpu.imgui.ImGuiImpl;
import uk.aidanlee.resources.ResourceSystem;
import uk.aidanlee.resources.Resource;
import uk.aidanlee.scene.Scene;
import imgui.ImGui;
import imgui.util.ImVec2;

typedef UserConfig = {};

class Main extends Flurry
{
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
        root = new SampleScene('root', app, null, renderer, resources, events);
        root.resumeOnCreation = true;
        root.create();
    }

    override function onUpdate(_dt : Float)
    {
        root.update(_dt);
    }

    override function onPostUpdate()
    {
        uiShowRenderStats();
    }

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