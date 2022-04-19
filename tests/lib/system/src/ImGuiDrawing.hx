package;

import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import VectorMath;
import uk.aidanlee.flurry.api.gpu.shaders.ShaderID;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.resources.parcels.Preload;
import uk.aidanlee.flurry.api.resources.parcels.Shaders;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.modules.imgui.DearImGui;
import imgui.ImGui;

class ImGuiDrawing extends Flurry
{
    var pipeline : PipelineID;

    var camera : Camera2D;

    var imgui : DearImGui;

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
        pipeline = renderer.createPipeline({ shader : new ShaderID(Shaders.textured) });
        camera   = new Camera2D(vec2(0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
        imgui    = new DearImGui(renderer, display, input);
    }

    override function onUpdate(_dt : Float)
    {
        imgui.newFrame();

        ImGui.showDemoWindow();
    }

    override function onRender(_ctx : GraphicsContext)
    {
        _ctx.usePipeline(pipeline);
        _ctx.useCamera(camera);

        imgui.draw(_ctx);
    }
}
