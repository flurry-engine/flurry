package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.modules.imgui.ImGuiImpl;
import imgui.NativeImGui;

class ImGuiDrawing extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = PrePackaged('preload');

        return _config;
    }

    override function onReady()
    {
        new ImGuiImpl(events, display, resources, input, renderer);
    }

    override function onUpdate(_dt : Float)
    {
        NativeImGui.showDemoWindow();
    }
}
