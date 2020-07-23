package;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.painter.Painter;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class Painting extends Flurry
{
    var camera : Camera2D;

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
        painter = new Painter(renderer.backend.queue, camera, resources.getByName('textured', ShaderResource).id);
    }

    override function onUpdate(_dt)
    {
        painter.begin();
        painter.drawFrame(resources.getByName('tank2', ImageFrameResource),   0, 128);

        final f = resources.getByName('ui_frame', ImageFrameResource);
        final i = resources.getByID(f.image, ImageResource);

        painter.drawNineSlice(f, i, 32, 32, 256, 96, 25, 25, 25, 25);
        painter.drawFrame(resources.getByName('tank1', ImageFrameResource), 256, 128);
        painter.drawFrame(resources.getByName('tank2', ImageFrameResource), 512, 128);
        painter.end();
    }
}
