package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.SpriteGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;

class Sprites extends Flurry
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
        final batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });
        final sprite  = resources.get('character', SpriteResource);

        for (i in 0...sprite.animations['default'].length)
        {
            new SpriteGeometry({
                batchers  : [ batcher ],
                sprite    : sprite,
                animation : 'default',
                x : 64 + (i * 128),
                y : 64,
                xOrigin : 8,
                yOrigin : 8,
                xScale  : 5,
                yScale  : 5
            }).frame(i);
        }
    }
}
