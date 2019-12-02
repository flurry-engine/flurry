package;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class Colourised extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = PrePackaged('preload');

        return _config;
    }

    override function onReady()
    {
        var camera  = new Camera2D(display.width, display.height);
        var batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        var g1 = new QuadGeometry({ textures : [ resources.get('tank1', ImageResource) ], batchers : [ batcher ] });
        var g2 = new QuadGeometry({ textures : [ resources.get('tank2', ImageResource) ], batchers : [ batcher ] });
        var g3 = new QuadGeometry({ textures : [ resources.get('tank3', ImageResource) ], batchers : [ batcher ] });

        g1.position.set_xy(  0, 128);
        g2.position.set_xy(256, 128);
        g3.position.set_xy(512, 128);

        for (v in g1.vertices)
        {
            v.color.fromRGBA(1, 0, 0, 1);
        }

        for (v in g2.vertices)
        {
            v.color.fromRGBA(0, 1, 0, 1);
        }

        for (v in g3.vertices)
        {
            v.color.fromRGBA(0, 0, 1, 1);
        }
    }
}
