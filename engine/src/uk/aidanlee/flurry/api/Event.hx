package uk.aidanlee.flurry.api;

/**
 * These are the core event strings which are emitted by the flurry engine.
 * Any additional part of the engine which has access to the central event bus can listen to these events.
 */
enum abstract Event(String) from String to String
{
    var Init          = 'flurry-core-ev-init';
    
    var Ready         = 'flurry-core-ev-ready';

    var PreUpdate     = 'flurry-core-ev-pre-update';

    var Update        = 'flurry-core-ev-update';

    var PostUpdate    = 'flurry-core-ev-post-update';

    var Shutdown      = 'flurry-core-ev-shutdown';

    var KeyUp         = 'flurry-core-ev-key-up';

    var KeyDown       = 'flurry-core-ev-key-down';

    var TextInput     = 'flurry-core-ev-text-input';

    var MouseUp       = 'flurry-core-ev-mouse-up';

    var MouseDown     = 'flurry-core-ev-mouse-down';

    var MouseMove     = 'flurry-core-ev-mouse-move';

    var MouseWheel    = 'flurry-core-ev-mouse-wheel';

    var GamepadUp     = 'flurry-core-ev-gamepad-up';

    var GamepadDown   = 'flurry-core-ev-gamepad-down';

    var GamepadAxis   = 'flurry-core-ev-gamepad-axis';

    var GamepadDevice = 'flurry-core-ev-gamepad-device';
}
