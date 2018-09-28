package;

import snow.api.Debug._debug;

/**
 * CLI runtime for snow.
 * Runs an infinite loop sending tick updates each iteration until shutdown is called.
 */
class TestRuntime extends snow.core.native.Runtime
{
    public function new(_app : snow.Snow)
    {
        super(_app);
    }

    public override function run() : Bool
    {
        _debug('cli / run');

        return loop();
    }

    inline public static function timestamp() : Float
    {
        return haxe.Timer.stamp();
    }

    private function loop() : Bool
    {
        _debug('cli / running main loop');

        while (!app.shutting_down)
        {
            app.dispatch_event(se_tick);
        }

        return true;
    }
}

@:noCompletion typedef RuntimeConfig = {}
@:noCompletion typedef WindowHandle = Int
