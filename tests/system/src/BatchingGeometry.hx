package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class BatchingGeometry extends Flurry
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
        final camera  = renderer.createCamera2D(display.width, display.height);
        final batcher = renderer.createBatcher({ shader : resources.getByName('textured', ShaderResource).id, camera : camera });

        new QuadGeometry({
            texture  : resources.getByName('tank2', ImageFrameResource),
            batchers : [ batcher ],
            y : 128
        });

        new QuadGeometry({
            texture  : resources.getByName('tank1', ImageFrameResource),
            batchers : [ batcher ],
            x : 256, y : 128
        });

        new QuadGeometry({
            texture  : resources.getByName('tank2', ImageFrameResource),
            batchers : [ batcher ],
            x : 512, y : 128
        });
    }
}
