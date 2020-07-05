package;

import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.modules.imgui.ImGuiImpl;
import imgui.ImGui;

class ImGuiDrawing extends Flurry
{
    var imgui : ImGuiImpl;

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = [ 'preload', 'shaders' ];

        return _config;
    }

    override function onReady()
    {
        imgui = new ImGuiImpl(events, display, resources, input, renderer, resources.get('textured', ShaderResource));
    }

    override function onPreUpdate()
    {
        imgui.newFrame();
    }

    override function onPreRender()
    {
        imgui.render();
    }

    override function onUpdate(_dt : Float)
    {
        ImGui.showAboutWindow();
    }

    override function onShutdown()
    {
        imgui.dispose();
    }
}
