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

using uk.aidanlee.flurry.api.gpu.drawing.Text;
using uk.aidanlee.flurry.api.gpu.drawing.Shapes;
using uk.aidanlee.flurry.api.gpu.drawing.Frames;
using uk.aidanlee.flurry.api.gpu.drawing.Surfaces;
using hxrx.schedulers.IScheduler;

class Text extends Flurry
{
    var pipeline1 : PipelineID;

    var pipeline2 : PipelineID;

    var pipeline3 : PipelineID;

    var camera : Camera2D;

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
        pipeline1 = renderer.createPipeline({ shader: new ShaderID(Shaders.textured) });
        pipeline2 = renderer.createPipeline({ shader: new ShaderID(Shaders.shapes) });
        pipeline3 = renderer.createPipeline({ shader: new ShaderID(Shaders.msdf) });
        camera    = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
    }

    override function onRender(_ctx : GraphicsContext)
    {
        // Draw a tiled background
        _ctx.usePipeline(pipeline1);
        _ctx.useCamera(camera);
        _ctx.drawFrameTiled(cast resources.get(Preload.background), vec2(0, 0), vec2(display.width, display.height));

        // Draw some text
        _ctx.usePipeline(pipeline3);
        _ctx.useCamera(camera);
        _ctx.drawText(cast resources.get(Preload.roboto), 'Hello World!', vec2(256, 256), vec2(0.5), vec2(64), 45);
    }
}
