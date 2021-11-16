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
using uk.aidanlee.flurry.api.gpu.drawing.Shapes;
using uk.aidanlee.flurry.api.gpu.drawing.Surfaces;
using hxrx.schedulers.IScheduler;

class Shapes extends Flurry
{
    var pipeline1 : PipelineID;

    var pipeline2 : PipelineID;

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
        camera    = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
    }

    override function onRender(_ctx : GraphicsContext)
    {
        // Draw a tiled background
        _ctx.usePipeline(pipeline1);
        _ctx.useCamera(camera);
        _ctx.drawFrameTiled(cast resources.get(Preload.background), vec2(0, 0), vec2(display.width, display.height));

        // Draw shapes
        _ctx.usePipeline(pipeline2);
        _ctx.useCamera(camera);

        _ctx.drawCircle(vec2(128, 128), 64);

        _ctx.drawPolygon(vec2(384, 128), 64, 5);

        _ctx.drawPolygonOutline(vec2(640, 128), 64, 8, 24, vec4(1, 0, 0, 0.5));

        _ctx.drawCircleOutline(vec2(128, 384), 64, 24);

        _ctx.drawTriangle(vec2(384, 320), vec2(320, 448), vec2(448, 448), vec4(1, 0, 1, 1));

        _ctx.drawSegment(vec2(640, 384), 64, 45, 160);

        _ctx.drawArc(vec2(640, 384), 64, 260, 110, 24, vec4(0, 0, 1, 1));
    }
}