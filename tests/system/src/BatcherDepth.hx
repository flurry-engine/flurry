import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.gpu.SurfaceID;
import haxe.ds.Vector;
import VectorMath;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.Colour;
import uk.aidanlee.flurry.api.gpu.ShaderID;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

using uk.aidanlee.flurry.api.gpu.drawing.Frames;

class BatcherDepth extends Flurry
{
    var pipeline : PipelineID;

    var colour : PipelineID;

    var format : PipelineID;

    var purple : PipelineID;
    
    var target : PipelineID;

    var surface : SurfaceID;

    var camera : Camera2D;

    var camera2 : Camera2D;

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
        surface  = renderer.createSurface(128, 128);
        pipeline = renderer.createPipeline({ shader: new ShaderID(Shaders.textured) });
        colour   = renderer.createPipeline({ shader: new ShaderID(Shaders.colourise) });
        format   = renderer.createPipeline({ shader: new ShaderID(Shaders.format) });
        purple   = renderer.createPipeline({ shader: new ShaderID(Shaders.purple) });
        target   = renderer.createPipeline({ shader: new ShaderID(Shaders.textured), surface: surface });
        camera   = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
        camera2  = new Camera2D(vec2(0, 0), vec2(128, 128), vec4(0, 0, 128, 128));
        uniform1 = new UniformBlobBuilder("colours").addVector4('colour', vec4(1.0, 0.5, 0.5, 1.0)).uniformBlob();
        uniform2 = new UniformBlobBuilder("colours").addVector4('colour', vec4(1.0, 0.5, 1.0, 1.0)).uniformBlob();
    }

    override function onUpdate(_dt : Float)
    {
        if (input.wasKeyPressed(Keycodes.space))
        {
            trace('deleting surface');

            renderer.deleteSurface(surface);
        }
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
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(704, 64), vec2(0.5, 0.5), vec2(1, 1), 0, Colour.yellow);
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(64, 192), vec2(0.5, 0.5), vec2(1, 1), 0, vec4(1, 1, 1, 0.5));

        _ctx.usePipeline(colour);
        _ctx.useCamera(camera);

        // These two uniforms occupy the same location in the shader so re-assigning it will flush whats been queued so far.
        _ctx.useUniformBlob(uniform1);
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(192, 192), vec2(0.5, 0.5));

        _ctx.useUniformBlob(uniform2);
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(320, 192), vec2(0.5, 0.5));

        // Different vertex format and custom drawing.
        _ctx.usePipeline(format);
        _ctx.useCamera(camera);

        drawCustomFrame(_ctx, cast resources.get(Preload.blue_worker), 384, 128);

        // Switch to yet another pipeline, this time just solid purple for all fragments.
        _ctx.usePipeline(purple);
        _ctx.useCamera(camera);

        _ctx.drawFrame(cast resources.get(Preload.blue_worker), vec2(512, 128));

        // Draw to surface
        _ctx.usePipeline(target);
        _ctx.useCamera(camera2);
        _ctx.drawFrame(cast resources.get(Preload.blue_worker), vec2(0, 0));

        // Then draw surface to backbuffer
        _ctx.usePipeline(pipeline);
        _ctx.useCamera(camera);

        drawSurface(_ctx, surface, 640, 128, 128, 128);
    }

    function drawCustomFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _x : Float, _y : Float)
    {
        _ctx.usePage(_frame.page);
        _ctx.prepare();
    
        // v1
        _ctx.vtxOutput.write(vec3(_x, _y + _frame.height, 0));
        _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v2));
    
        // v2
        _ctx.vtxOutput.write(vec3(_x, _y, 0));
        _ctx.vtxOutput.write(vec2(_frame.u1, _frame.v1));
    
        // v3
        _ctx.vtxOutput.write(vec3(_x + _frame.width, _y, 0));
        _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v1));
    
        // v4
        _ctx.vtxOutput.write(vec3(_x + _frame.width, _y + _frame.height, 0));
        _ctx.vtxOutput.write(vec2(_frame.u2, _frame.v2));
    
        // Indices
        _ctx.idxOutput.write(0);
        _ctx.idxOutput.write(1);
        _ctx.idxOutput.write(2);
    
        _ctx.idxOutput.write(0);
        _ctx.idxOutput.write(2);
        _ctx.idxOutput.write(3);
    }

    function drawSurface(_ctx : GraphicsContext, _surface : SurfaceID, _x : Float, _y : Float, _width : Int, _height : Int)
    {
        _ctx.useSurface(_surface);
        _ctx.prepare();
    
        // v1
        _ctx.vtxOutput.write(vec3(_x, _y + _height, 0));
        _ctx.vtxOutput.write(vec4(1));
        _ctx.vtxOutput.write(vec2(0, 1));
    
        // v2
        _ctx.vtxOutput.write(vec3(_x, _y, 0));
        _ctx.vtxOutput.write(vec4(1));
        _ctx.vtxOutput.write(vec2(0, 0));
    
        // v3
        _ctx.vtxOutput.write(vec3(_x + _width, _y, 0));
        _ctx.vtxOutput.write(vec4(1));
        _ctx.vtxOutput.write(vec2(1, 0));
    
        // v4
        _ctx.vtxOutput.write(vec3(_x + _width, _y + _height, 0));
        _ctx.vtxOutput.write(vec4(1));
        _ctx.vtxOutput.write(vec2(1, 1));
    
        // Indices
        _ctx.idxOutput.write(0);
        _ctx.idxOutput.write(1);
        _ctx.idxOutput.write(2);
    
        _ctx.idxOutput.write(0);
        _ctx.idxOutput.write(2);
        _ctx.idxOutput.write(3);
    }
}
