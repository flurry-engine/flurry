package;

import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class ClearColour extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.renderer.backend = Auto;

        _config.renderer.clearColour.r = 0.34;
        _config.renderer.clearColour.g = 0.10;
        _config.renderer.clearColour.b = 0.94;
        _config.renderer.clearColour.a = 1;

        return _config;
    }
}
