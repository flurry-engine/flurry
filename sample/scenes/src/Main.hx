package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.modules.scene.Scene;
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
        root = createTree();
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

    /**
     * Create a complex scene tree to ensure everything is working as planned.
     * @return Scene
     */
    function createTree() : Scene
    {
        var rootNode = new Scene('root', app, null, renderer, resources, events);
        var child1   = rootNode.addChild(Scene, 'root/child1');
        rootNode.addChild(Scene, 'root/child2');
        rootNode.addChild(Scene, 'root/child3');
        rootNode.addChild(Scene, 'root/child4');

        child1.addChild(Scene, 'root/child1/child1');
        child1.addChild(Scene, 'root/child1/child2').addChild(TestScene, 'root/child1/child2/child1');

        return rootNode;
    }
}
