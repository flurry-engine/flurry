package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;

class GeometryDepth extends Flurry
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
        final batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        new QuadGeometry({
            texture  : resources.get('tank1', ImageFrameResource),
            batchers : [ batcher ],
            depth    : 1,
            x : 192, y :  64, width : 256, height : 256
        });
        new QuadGeometry({
            texture  : resources.get('tank2', ImageFrameResource),
            batchers : [ batcher ],
            depth : 0,
            x : 256, y : 128, width : 256, height : 256
        });
        new QuadGeometry({
            texture  : resources.get('tank3', ImageFrameResource),
            batchers : [ batcher ],
            depth : 2,
            x : 320, y : 192, width : 256, height : 256
        });
    }
}
