package uk.aidanlee.flurry.api.input;

enum abstract GamepadButtons(Int) from Int to Int
{
    var GAMEPAD_BUTTON_INVALID       = -1;
    var GAMEPAD_BUTTON_A             =  0;
    var GAMEPAD_BUTTON_B             =  1;
    var GAMEPAD_BUTTON_X             =  2;
    var GAMEPAD_BUTTON_Y             =  3;
    var GAMEPAD_BUTTON_BACK          =  4;
    var GAMEPAD_BUTTON_GUIDE         =  5;
    var GAMEPAD_BUTTON_START         =  6;
    var GAMEPAD_BUTTON_LEFTSTICK     =  7;
    var GAMEPAD_BUTTON_RIGHTSTICK    =  8;
    var GAMEPAD_BUTTON_LEFTSHOULDER  =  9;
    var GAMEPAD_BUTTON_RIGHTSHOULDER = 10;
    var GAMEPAD_BUTTON_DPAD_UP       = 11;
    var GAMEPAD_BUTTON_DPAD_DOWN     = 12;
    var GAMEPAD_BUTTON_DPAD_LEFT     = 13;
    var GAMEPAD_BUTTON_DPAD_RIGHT    = 14;
    var GAMEPAD_BUTTON_MAX           = 15;

    var GAMEPAD_AXIS_LEFT_LEFT   = 101;
    var GAMEPAD_AXIS_LEFT_RIGHT  = 102;
    var GAMEPAD_AXIS_LEFT_UP     = 103;
    var GAMEPAD_AXIS_LEFT_DOWN   = 104;
    var GAMEPAD_AXIS_RIGHT_LEFT  = 105;
    var GAMEPAD_AXIS_RIGHT_RIGHT = 106;
    var GAMEPAD_AXIS_RIGHT_UP    = 107;
    var GAMEPAD_AXIS_RIGHT_DOWN  = 108;
    
    var GAMEPAD_TRIGGER_LEFT     = 109;
    var GAMEPAD_TRIGGER_RIGHT    = 110;
}

enum abstract GamepadAxes(Int) from Int to Int
{
    var GAMEPAD_AXIS_INVALID         = -1;
    var GAMEPAD_AXIS_LEFTX           =  0;
    var GAMEPAD_AXIS_LEFTY           =  1;
    var GAMEPAD_AXIS_RIGHTX          =  2;
    var GAMEPAD_AXIS_RIGHTY          =  3;
    var GAMEPAD_AXIS_TRIGGERLEFT     =  4;
    var GAMEPAD_AXIS_TRIGGERRIGHT    =  5;
    var GAMEPAD_AXIS_MAX             =  6;
}
