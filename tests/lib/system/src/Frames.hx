import VectorMath;
import haxe.io.Bytes;
import haxe.ds.Vector;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.Colour;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.shaders.ShaderID;
import uk.aidanlee.flurry.api.gpu.shaders.UniformBlob;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.resources.parcels.Preload;
import uk.aidanlee.flurry.api.resources.parcels.Shaders;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

using uk.aidanlee.flurry.api.gpu.drawing.Frames;
using uk.aidanlee.flurry.api.gpu.drawing.Surfaces;
using uk.aidanlee.flurry.api.gpu.drawing.Geometry;
using hxrx.schedulers.IScheduler;

class Frames extends Flurry
{
    var pipeline : PipelineID;

    var colour : PipelineID;

    var format : PipelineID;

    var purple : PipelineID;
    
    var target : PipelineID;

    var surface : SurfaceID;

    var camera : Camera2D;

    var camera2 : Camera2D;

    var uniform1 : uk.aidanlee.flurry.api.gpu.shaders.uniforms.Shaders.Colours;

    var uniform2 : uk.aidanlee.flurry.api.gpu.shaders.uniforms.Shaders.Colours;

    var geometry : Geometry;

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
        surface  = renderer.createSurface({ width : 128, height : 128 });
        pipeline = renderer.createPipeline({ shader: new ShaderID(Shaders.textured) });
        colour   = renderer.createPipeline({ shader: new ShaderID(Shaders.colourise) });
        format   = renderer.createPipeline({ shader: new ShaderID(Shaders.format) });
        purple   = renderer.createPipeline({ shader: new ShaderID(Shaders.purple) });
        target   = renderer.createPipeline({ shader: new ShaderID(Shaders.textured), surface: surface });
        camera   = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
        camera2  = new Camera2D(vec2(0, 0), vec2(128, 128), vec4(0, 0, 128, 128));
        uniform1 = new uk.aidanlee.flurry.api.gpu.shaders.uniforms.Shaders.Colours();
        uniform2 = new uk.aidanlee.flurry.api.gpu.shaders.uniforms.Shaders.Colours();
        geometry = buildCustomQuad();

        uniform1.colour = vec3(1.0, 0.5, 0.5);
        uniform2.colour = vec3(1.0, 0.5, 1.0);
    }

    override function onUpdate(_dt : Float)
    {
        if (input.wasKeyPressed(Keycodes.space))
        {
            final info = stb.Image.load('C:/Users/AidanLee/Downloads/small.png', 4);
            final data = ArrayBufferView.fromBytes(Bytes.ofData(info.bytes));

            renderer.updateTexture(
                cast resources.get(Preload.blue_king),
                data);
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
        _ctx.drawFrameScaled(cast resources.get(Preload.die), vec2(384, 48), vec2(0, 0), vec2(2, 0.5));
        _ctx.drawFrameScaled(cast resources.get(Preload.die), vec2(573, 64), vec2(0.5, 0.5), vec2(0.75, 2.25), 45);

        // Draw a colourised and semi-transparent frame
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(704, 64), vec2(0.5, 0.5), 0, Colour.yellow);
        _ctx.drawFrame(cast resources.get(Preload.emote_angry), vec2(64, 192), vec2(0.5, 0.5), 0, vec4(1, 1, 1, 0.5));

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

        _ctx.drawSurface(surface, vec2(640, 128), vec2(128, 128));

        _ctx.drawGeometry(geometry);
    }

    function drawCustomFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _x : Float, _y : Float)
    {
        _ctx.usePage(0, _frame.page, SamplerState.nearest);
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

    function buildCustomQuad()
    {
        final frame = resources.getAs(Preload.blue_worker, PageFrameResource);

        final vtxBlob =
            new VertexBlobBuilder()
                .addFloat3(0, 384, 0)
                .addFloat4(1, 1, 1, 1)
                .addFloat2(frame.u1, frame.v2)

                .addFloat3(0, 256, 0)
                .addFloat4(1, 1, 1, 1)
                .addFloat2(frame.u1, frame.v1)

                .addFloat3(128, 256, 0)
                .addFloat4(1, 1, 1, 1)
                .addFloat2(frame.u2, frame.v1)

                .addFloat3(128, 384, 0)
                .addFloat4(1, 1, 1, 1)
                .addFloat2(frame.u2, frame.v2)

                .vertexBlob();

        final idxBlob =
            new IndexBlobBuilder()
                .addInt(0)
                .addInt(1)
                .addInt(2)

                .addInt(0)
                .addInt(2)
                .addInt(3)

                .indexBlob();

        return new Geometry(vtxBlob, idxBlob, [ new GeometryInput(Left(frame.page), SamplerState.nearest) ], []);
    }
}
