package;

import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;
import tink.Cli;

typedef UserConfig = {};

class Main extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.renderer.backend = NULL;

        return _config;
    }

    override function onReady()
    {
        Cli.process(Sys.args(), new ParcelTool()).handle(Cli.exit);
    }
}
