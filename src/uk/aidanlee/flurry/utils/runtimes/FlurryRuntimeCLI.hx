package uk.aidanlee.flurry.utils.runtimes;

import snow.Snow;
import snow.api.Debug._debug;

typedef RuntimeConfig = {}
typedef WindowHandle = Int;

class FlurryRuntimeCLI extends snow.core.native.Runtime
{
    final flurry : Flurry;

    public function new(_snow : Snow)
    {
        super(_snow);

        flurry = app.host;

        _debug('cli / init ok');
    }

    public static function timestamp() : Float
    {
        return haxe.Timer.stamp();
    }

    override public function run() : Bool
    {
        _debug('cli / run');

        return loop();
    }

    function loop() : Bool
    {
        _debug('cli / running main loop');

        while (!app.shutting_down)
        {
            app.dispatch_event(se_tick);
        }

        return true;
    }
}
