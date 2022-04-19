import uk.aidanlee.flurry.api.gpu.pipeline.StencilState;
import VectorMath;
import haxe.io.Bytes;
import haxe.ds.Vector;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.Colour;
import uk.aidanlee.flurry.api.gpu.ShaderID;
import uk.aidanlee.flurry.api.gpu.SurfaceID;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

using uk.aidanlee.flurry.api.gpu.drawing.Frames;
using uk.aidanlee.flurry.api.gpu.drawing.Surfaces;
using hxrx.schedulers.IScheduler;

class StencilTesting extends Flurry
{
    var camera : Camera2D;

    var background : PipelineID;

    var stencil : PipelineID;

    var drawing : PipelineID;

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
        camera     = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
        background = renderer.createPipeline({ shader: new ShaderID(Shaders.textured) });
        stencil    = renderer.createPipeline({
            shader  : new ShaderID(Shaders.textured),
            stencil : new StencilState(true, Equal, Replace, Keep, Keep, Equal, Replace, Keep, Keep)
        });
        drawing    = renderer.createPipeline({
            shader  : new ShaderID(Shaders.textured),
            stencil : new StencilState(true, NotEqual, Replace, Keep, Keep, NotEqual, Replace, Keep, Keep)
        });
    }

    override function onRender(_ctx : GraphicsContext)
    {
        // Draw a tiled background and large king
        _ctx.usePipeline(background);
        _ctx.useCamera(camera);
        _ctx.drawFrameTiled(cast resources.get(Preload.background), vec2(0, 0), vec2(display.width, display.height));

        // Draw the mask into the stencil buffer
        _ctx.usePipeline(stencil);
        _ctx.useCamera(camera);
        _ctx.drawFrame(cast resources.get(Preload.blue_king), vec2(display.width * 0.5, display.height * 0.5), vec2(0.5, 0.5));

        _ctx.usePipeline(drawing);
        _ctx.useCamera(camera);
        _ctx.drawFrameScaled(cast resources.get(Preload.blue_king), vec2(display.width * 0.5, display.height * 0.5), vec2(0.5, 0.5), vec2(2));
    }
}
