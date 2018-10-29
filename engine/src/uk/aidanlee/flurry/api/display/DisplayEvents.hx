package uk.aidanlee.flurry.api.display;

enum abstract DisplayEvents(String) from String to String
{
    var Unknown     = 'flurry-window-ev-unknown';

    var Shown       = 'flurry-window-ev-shown';

    var Hidden      = 'flurry-window-ev-hidden';

    var Exposed     = 'flurry-window-ev-exposed';

    var Moved       = 'flurry-window-ev-moved';

    var Minimised   = 'flurry-window-ev-minimised';

    var Maximised   = 'flurry-window-ev-maximised';

    var Restored    = 'flurry-window-ev-restored';

    var Enter       = 'flurry-window-ev-Enter';

    var Leave       = 'flurry-window-ev-Leave';

    var FocusGained = 'flurry-window-ev-focus-gained';

    var FocusLost   = 'flurry-window-ev-focus-lost';

    var Close       = 'flurry-window-ev-close';

    var Resized     = 'flurry-window-ev-resized';

    var SizeChanged = 'flurry-window-ev-size-changed';
}

class DisplayEventData
{
    public final width : Int;

    public final height : Int;

    public function new(_width : Int, _height : Int)
    {
        width  = _width;
        height = _height;
    }
}
