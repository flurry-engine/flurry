package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;

class ClearColour extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = 'preload';

        _config.renderer.ogl3.clearColour.x = 0.34;
        _config.renderer.ogl3.clearColour.y = 0.10;
        _config.renderer.ogl3.clearColour.z = 0.94;
        _config.renderer.ogl3.clearColour.w = 1;

        return _config;
    }
}
