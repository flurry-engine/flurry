package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class BatcherDepth extends Flurry
{
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
        final camera   = renderer.createCamera2D(display.width, display.height);
        final batcher1 = renderer.createBatcher({ shader : resources.getByName('textured', ShaderResource), camera : camera, depth : 1 });
        final batcher2 = renderer.createBatcher({ shader : resources.getByName('textured', ShaderResource), camera : camera, depth : 0 });
        final batcher3 = renderer.createBatcher({ shader : resources.getByName('textured', ShaderResource), camera : camera, depth : 2 });

        new QuadGeometry({
            texture  : resources.getByName('tank1', ImageFrameResource),
            batchers : [ batcher1 ],
            x : 192, y : 64, width : 256, height : 256
        });
        new QuadGeometry({
            texture  : resources.getByName('tank2', ImageFrameResource),
            batchers : [ batcher2 ],
            x : 256, y : 128, width : 256, height : 256
        });
        new QuadGeometry({
            texture  : resources.getByName('tank3', ImageFrameResource),
            batchers : [ batcher3 ],
            x : 320, y : 192, width : 256, height : 256
        });
    }
}
