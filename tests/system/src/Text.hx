package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.TextResource;
import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontParser;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.TextGeometry;
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
        final batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });
        final font    = BitmapFontParser.parse(resources.get('ubuntu.fnt', TextResource).content);

        new TextGeometry({
            batchers : [ batcher ],
            texture  : resources.get('ubuntu.png', ImageResource),
            font     : font,
            text     : 'hello world',
            x : 32, y : 32
        });

        new TextGeometry({
            batchers : [ batcher ],
            texture  : resources.get('ubuntu.png', ImageResource),
            font     : font,
            text     : 'Lorem ipsum',
            x : 32, y : 48
        }).scale.set_xy(2, 2);
    }
}
