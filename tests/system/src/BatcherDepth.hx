import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import haxe.ds.Vector;
import VectorMath;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.Colour;
import uk.aidanlee.flurry.api.gpu.ShaderID;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

using uk.aidanlee.flurry.api.gpu.drawing.Frames;

class BatcherDepth extends Flurry
{
    var pipeline : PipelineID;

    var solid : PipelineID;

    var camera : Camera2D;

    var uniform1 : UniformBlob;

    var uniform2 : UniformBlob;

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
        pipeline = renderer.createPipeline({ shader: new ShaderID(Shaders.textured) });
        solid    = renderer.createPipeline({ shader: new ShaderID(Shaders.colourise) });
        camera   = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
        uniform1 = new UniformBlobBuilder("colours").addVector4('colour', vec4(1.0, 0.5, 0.5, 1.0)).uniformBlob();
        uniform2 = new UniformBlobBuilder("colours").addVector4('colour', vec4(1.0, 0.5, 1.0, 1.0)).uniformBlob();
    }

    override function onRender(_ctx : GraphicsContext)
    {
        _ctx.usePipeline(pipeline);
        _ctx.useCamera(camera);

        // Draw a tiled background
        _ctx.drawFrameTiled(cast resources.get(Preload.background), vec2(0, 0), vec2(display.width, display.height));

        // Non rotated drawing and origins
        _ctx.drawFrame(cast resources.get(Preload.blue_worker), vec2(0, 0));
        _ctx.drawFrame(cast resources.get(Preload.blue_king), vec2(192, 64), vec2(0.5, 0.5));

        // Rotating around an origin
        _ctx.drawFrame(cast resources.get(Preload.blue_shield), vec2(320, 64), vec2(0.5, 0.5), -45);

        // Scaling and rotated scaling around an origin
        _ctx.drawFrame(cast resources.get(Preload.die), vec2(384, 48), vec2(0, 0), vec2(2, 0.5));
        _ctx.drawFrame(cast resources.get(Preload.die), vec2(573, 64), vec2(0.5, 0.5), vec2(0.75, 2.25), 45);

        // Draw a colourised and semi-transparent frame
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(704, 64), vec2(0.5, 0.5), vec2(1, 1), 0, yellow());
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(64, 192), vec2(0.5, 0.5), vec2(1, 1), 0, vec4(1, 1, 1, 0.5));

        _ctx.usePipeline(solid);
        _ctx.useCamera(camera);

        // Setting a uniform blob which has already been assigned will flush the current data automatically.
        _ctx.useUniformBlob(uniform1);
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(192, 192), vec2(0.5, 0.5));

        _ctx.useUniformBlob(uniform2);
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(320, 192), vec2(0.5, 0.5));
    }
}
