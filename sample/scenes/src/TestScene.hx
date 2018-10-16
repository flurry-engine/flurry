package;

import uk.aidanlee.flurry.modules.scene.Scene;

class TestScene extends Scene
{
    override function onCreated<T>(?_data:T = null)
    {
        trace('created');
    }

    override function onResumed<T>(?_data:T = null)
    {
        trace('resumed');
    }

    override function onPaused<T>(?_data:T = null)
    {
        trace('paused');
    }

    override function onRemoved<T>(?_data:T = null)
    {
        trace('removed');
    }
}
