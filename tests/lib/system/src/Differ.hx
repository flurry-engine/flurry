import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import haxe.Timer;
import uk.aidanlee.flurry.modules.differ.shapes.Polygon;
import VectorMath;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.shaders.ShaderID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.resources.parcels.Preload;
import uk.aidanlee.flurry.api.resources.parcels.Shaders;
import uk.aidanlee.flurry.api.gpu.drawing.Frames;
import uk.aidanlee.flurry.api.gpu.drawing.Shapes;
import uk.aidanlee.flurry.modules.differ.sat.SAT2D;
import uk.aidanlee.flurry.modules.differ.shapes.Circle;

class Differ extends Flurry
{
    var pipeline : PipelineID;

    var shapes : PipelineID;

    var camera : Camera2D;

    var p0 : Vec2;

    var p1 : Vec2;

    override function onConfig(_config : FlurryConfig)
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
        shapes   = renderer.createPipeline({ shader: new ShaderID(Shaders.shapes) });
        camera   = new Camera2D(vec2(0, 0), vec2(display.width, display.height), vec4(0, 0, display.width, display.height));

        trace('HELLO');
        trace('WORLD');
        trace('TEST1');
        trace('TEST2');

        p0 = vec2( 64,  64);
        p1 = vec2(256, 256);
    }

    override function onRender(_ctx : GraphicsContext)
    {
        _ctx.usePipeline(pipeline);
        _ctx.useCamera(camera);

        // Draw a tiled background
        drawFrameTiled(_ctx, cast resources.get(Preload.background), vec2(0, 0), vec2(display.width, display.height));

        _ctx.usePipeline(shapes);
        _ctx.useCamera(camera);

        // final circle1 = new Circle(vec2(128, 128), 1, 32);
        // final circle2 = new Circle(vec2(display.mouseX, display.mouseY), 1.5, 32);

        // switch testCircleVsCircle(circle1, circle2)
        // {
        //     case null:
        //         drawCircleOutline(_ctx, vec2(display.mouseX, display.mouseY), 32 * 1.5, 2);
        //         drawCircleOutline(_ctx, vec2(128, 128), 32, 2);
        //     case hit:
        //         drawCircleOutline(_ctx, vec2(display.mouseX, display.mouseY), 32 * 1.5, 2, vec4(0.5, 0.5, 0.5, 0.5));
        //         drawCircleOutline(_ctx, vec2(display.mouseX, display.mouseY) - hit.separation, 32 * 1.5, 2, vec4(1, 0, 0, 1));
        //         drawCircleOutline(_ctx, vec2(128, 128), 32, 2, vec4(1, 0, 0, 1));
        // }

        // final polygon1 = Polygon.ngon(vec2(256, 256), 8, 32);
        // final polygon2 = Polygon.rectangle(vec2(display.mouseX, display.mouseY), vec2(16), true);
        // polygon2.angle = degrees(Math.abs(Math.sin(Timer.stamp())));

        // switch testPolygonVsPolygon(polygon1, polygon2)
        // {
        //     case null:
        //         polygon1.draw(_ctx, vec4(1));
        //         polygon2.draw(_ctx, vec4(1));
        //     case hit:
        //         polygon1.draw(_ctx, vec4(1));
        //         polygon2.draw(_ctx, vec4(0.5, 0.5, 0.5, 0.5));

        //         polygon2.pos += hit.other.separation;
        //         polygon2.draw(_ctx, vec4(1, 0, 0, 1));
        // }

        // final polygon = Polygon.ngon(vec2(256, 256), 8, 32);
        // final circle  = new Circle(vec2(display.mouseX, display.mouseY), 1.5, 32);

        // switch testCircleVsPolygon(circle, polygon)
        // {
        //     case null:
        //         polygon.draw(_ctx, vec4(1));
        //         drawCircleOutline(_ctx, vec2(display.mouseX, display.mouseY), 32 * 1.5, 2);
        //     case hit:
        //         polygon.draw(_ctx, vec4(1));
        //         drawCircleOutline(_ctx, vec2(display.mouseX, display.mouseY), 32 * 1.5, 2, vec4(0.5, 0.5, 0.5, 0.5));

        //         circle.pos += hit.separation;
        //         drawCircleOutline(_ctx, circle.pos, circle.radius * circle.scale, 2, vec4(1, 0, 0, 1));
        // }

        final cursor = vec2(display.mouseX, display.mouseY);
        final ray    = new Ray(p0, p1, Infinite);
        final circle = new Circle(vec2(128, 384), 1, 64);

        if (cursor.distance(p0) < 8 && input.isMouseDown(1))
        {
            p0 = cursor;
        }
        if (cursor.distance(p1) < 8 && input.isMouseDown(1))
        {
            p1 = cursor;
        }

        drawLine(_ctx, p0, p1, 2);
        drawCircleOutline(_ctx, p0, 8, 2);
        drawCircleOutline(_ctx, p1, 8, 2);

        switch testRayVsCircle(ray, circle)
        {
            case null:
                drawCircle(_ctx, circle.pos, circle.radius);
            case result:
                drawCircleOutline(_ctx, circle.pos, circle.radius, vec4(0.5));
                drawCircle(_ctx, result.hitStart(ray), 4);
                drawCircle(_ctx, result.hitEnd(ray), 4);
        }
    }
}