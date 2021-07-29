package;

import VectorMath;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.ShaderID;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

class BatcherDepth extends Flurry
{
    var pipeline : PipelineID;

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
        pipeline = renderer.createPipeline({ shader: new ShaderID(Shaders.textured) });
        camera   = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));
    }

    override function onRender(_ctx : GraphicsContext)
    {
        _ctx.usePipeline(pipeline);
        _ctx.useCamera(camera);

        drawFrame(_ctx, cast resources.get(Preload.tank1), 192, 64);
        drawFrame(_ctx, cast resources.get(Preload.tank2), 256, 128);
        drawFrame(_ctx, cast resources.get(Preload.tank3), 320, 192);
    }

    static function drawFrame(_ctx : GraphicsContext, _frame : PageFrameResource, _x : Float, _y : Float)
    {
        _ctx.usePage(_frame.page);
        _ctx.prepare();

        // v1
        _ctx.vtxOutput.writeFloat(_x);
        _ctx.vtxOutput.writeFloat(_y + _frame.height);
        _ctx.vtxOutput.writeFloat(0);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(_frame.u1);
        _ctx.vtxOutput.writeFloat(_frame.v2);

        // v2
        _ctx.vtxOutput.writeFloat(_x);
        _ctx.vtxOutput.writeFloat(_y);
        _ctx.vtxOutput.writeFloat(0);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(_frame.u1);
        _ctx.vtxOutput.writeFloat(_frame.v1);

        // v3
        _ctx.vtxOutput.writeFloat(_x + _frame.width);
        _ctx.vtxOutput.writeFloat(_y);
        _ctx.vtxOutput.writeFloat(0);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(_frame.u2);
        _ctx.vtxOutput.writeFloat(_frame.v1);

        // v4
        _ctx.vtxOutput.writeFloat(_x + _frame.width);
        _ctx.vtxOutput.writeFloat(_y + _frame.height);
        _ctx.vtxOutput.writeFloat(0);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(1);
        _ctx.vtxOutput.writeFloat(_frame.u2);
        _ctx.vtxOutput.writeFloat(_frame.v2);

        // Indices
        _ctx.idxOutput.writeUInt16(0);
        _ctx.idxOutput.writeUInt16(1);
        _ctx.idxOutput.writeUInt16(2);

        _ctx.idxOutput.writeUInt16(0);
        _ctx.idxOutput.writeUInt16(2);
        _ctx.idxOutput.writeUInt16(3);
    }
}
