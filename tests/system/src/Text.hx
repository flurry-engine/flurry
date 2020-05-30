package;

import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.TextGeometry;
import uk.aidanlee.flurry.api.resources.Resource.FontResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class Text extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = 'preload';

        return _config;
    }

    override function onReady()
    {
        final camera  = renderer.createCamera2D(display.width, display.height);
        final batcher = renderer.createBatcher({ shader : resources.get('msdf', ShaderResource), camera : camera });
        final sampler = new SamplerState(Clamp, Clamp, Linear, Linear);

        new TextGeometry({
            batchers : [ batcher ],
            font     : resources.get('ubuntu', FontResource),
            sampler  : sampler,
            text     : 'hello world',
            size     : 48,
            x : 32, y : 32
        });

        new TextGeometry({
            batchers : [ batcher ],
            font     : resources.get('ubuntu', FontResource),
            sampler  : sampler,
            text     : 'Lorem ipsum',
            size     : 96,
            x : 32, y : 96
        });
    }
}
