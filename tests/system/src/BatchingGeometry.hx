package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;

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
        final batcher = renderer.createBatcher({ shader : Shaders.textured, camera : camera });

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank2),
            batchers : [ batcher ],
            y : 128
        });

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank1),
            batchers : [ batcher ],
            x : 256, y : 128
        });

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank2),
            batchers : [ batcher ],
            x : 512, y : 128
        });
    }
}
