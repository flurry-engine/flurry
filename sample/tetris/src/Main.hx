package;

import uk.aidanlee.Flurry;
import uk.aidanlee.FlurryConfig;
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
        _config.resources.preload.images.push({ id : 'assets/images/shapes.png' });
        _config.resources.preload.texts.push({ id : 'assets/images/shapes.atlas' });

        return _config;
    }

    /**
     * Once snow is ready we can create our engine instances and load a parcel with some default assets.
     */
    override function onReady()
    {
        // Setup a default root scene, in the future users will specify their root scene.
        root = new TetrisScene('root', app, null, renderer, resources, null);
        root.resumeOnCreation = true;
        root.create();
    }

    /**
     * Simulate all of the engines components.
     * @param _dt 
     */
    override function onUpdate(_dt : Float)
    {
        root.update(_dt);
    }

    override function onPostUpdate()
    {
        uiShowRenderStats();
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