package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;

class TransformationTree extends Flurry
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

        final g1 = new QuadGeometry({ texture : resources.getByName('tank1', ImageFrameResource), batchers : [ batcher ], x : 256, y : 128, width : 256, height : 256 });

        final g2 = new QuadGeometry({ texture : resources.getByName('tank2', ImageFrameResource), batchers : [ batcher ], x : 64, y : 48, width : 256, height : 256 });
        g2.transformation.parent = g1.transformation;

        final g3 = new QuadGeometry({ texture : resources.getByName('tank3', ImageFrameResource), batchers : [ batcher ], x : 32, y : -24, width : 256, height : 256 });
        g3.transformation.parent = g2.transformation;
    }
}
