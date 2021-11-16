package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.batcher.Painter;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

class Painting extends Flurry
{
    var camera : Camera2D;

    var batcher : Batcher;

    var painter : Painter;

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
        camera  = renderer.createCamera2D(display.width, display.height);
        batcher = renderer.createBatcher({ shader : resources.getByName('textured', ShaderResource).id, camera : camera, depth : 0 });
        painter = renderer.createPainter({ shader : resources.getByName('textured', ShaderResource).id, camera : camera, depth : 1 });

        new QuadGeometry({
            texture  : resources.getByName('tank1', ImageFrameResource),
            batchers : [ batcher ],
            x : 0, y : 128
        });
    }

    override function onUpdate(_dt)
    {
        painter.begin();

        painter.pushColour(new Vector4(1, 0, 0, 1));
        painter.drawFrame(resources.getByName('tank3', ImageFrameResource), 512, 128);
        painter.popColour();

        final f = resources.getByName('ui_frame', ImageFrameResource);
        final i = resources.getByID(f.image, ImageResource);

        painter.pushSampler(SamplerState.linear);
        painter.drawNineSlice(f, i, 32, 32, 256, 96, 25, 25, 25, 25);
        painter.popSampler();

        painter.drawFrame(resources.getByName('tank2', ImageFrameResource), 256, 128);

        painter.pushShader(resources.getByName('purple', ShaderResource).id);
        painter.drawLine(48, 32, 560, 277);
        painter.drawRectangle(48, 32, 512, 245);
        painter.drawRectangleFilled(80, 64, 448, 181);
        painter.popShader();

        painter.drawSprite(resources.getByName('character', SpriteResource), 'default', 2, 128, 384, true, false);

        painter.end();
    }
}
