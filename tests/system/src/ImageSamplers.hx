package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;

class ImageSamplers extends Flurry
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
        var camera  = renderer.createCamera2D(display.width, display.height);
        var batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        new QuadGeometry({
            texture  : resources.get('van', ImageResource),
            batchers : [ batcher ],
            x : 256, y : 128, width : 128, height : 128
        });

        new QuadGeometry({
            texture  : resources.get('van', ImageResource),
            sampler  : new SamplerState(Wrap, Wrap, Nearest, Nearest),
            batchers : [ batcher ],
            x : 384, y : 128, width : 128, height : 128
        });

        new QuadGeometry({
            texture  : resources.get('van', ImageResource),
            sampler  : new SamplerState(Mirror, Mirror, Linear, Linear),
            batchers : [ batcher ],
            x : 256, y : 256, width : 128, height : 128
        }).uv_xyzw(0, 0, 2, 2);

        new QuadGeometry({
            texture  : resources.get('van', ImageResource),
            sampler  : new SamplerState(Wrap, Wrap, Linear, Linear),
            batchers : [ batcher ],
            x : 384, y : 256, width : 128, height : 128
        }).uv_xyzw(0, 0, 2, 2);
    }
}
