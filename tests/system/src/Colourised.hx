package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;

class Colourised extends Flurry
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
            texture  : cast resources.get(Preload.tank1),
            batchers : [ batcher ],
            x : 0, y : 128, width : 256, height : 256
        }).setColour(1, 0, 0, 1);

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank2),
            batchers : [ batcher ],
            x : 256, y : 128, width : 256, height : 256
        }).setColour(0, 1, 0, 1);
        
        new QuadGeometry({
            texture  : cast resources.get(Preload.tank3),
            batchers : [ batcher ],
            x : 512, y : 129, width : 256, height : 256
        }).setColour(0, 0, 1, 1);
    }
}
