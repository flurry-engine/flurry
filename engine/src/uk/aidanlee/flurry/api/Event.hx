package uk.aidanlee.flurry.api;

/**
 * These are the core event strings which are emitted by the flurry engine.
 * Any additional part of the engine which has access to the central event bus can listen to these events.
 */
class Event
{
    public static var INIT           = 'flurry-core-ev-init';
    
    public static var READY          = 'flurry-core-ev-ready';

    public static var PRE_UPDATE     = 'flurry-core-ev-pre-update';

    public static var UPDATE         = 'flurry-core-ev-update';

    public static var POST_UPDATE    = 'flurry-core-ev-post-update';

    public static var SHUTDOWN       = 'flurry-core-ev-shutdown';

    public static var KEY_UP         = 'flurry-core-ev-key-up';

    public static var KEY_DOWN       = 'flurry-core-ev-key-down';

    public static var TEXT_INPUT     = 'flurry-core-ev-text-input';

    public static var MOUSE_UP       = 'flurry-core-ev-mouse-up';

    public static var MOUSE_DOWN     = 'flurry-core-ev-mouse-down';

    public static var MOUSE_MOVE     = 'flurry-core-ev-mouse-move';

    public static var MOUSE_WHEEL    = 'flurry-core-ev-mouse-wheel';

    public static var GAMEPAD_UP     = 'flurry-core-ev-gamepad-up';

    public static var GAMEPAD_DOWN   = 'flurry-core-ev-gamepad-down';

    public static var GAMEPAD_AXIS   = 'flurry-core-ev-gamepad-axis';

    public static var GAMEPAD_DEVICE = 'flurry-core-ev-gamepad-device';
}
