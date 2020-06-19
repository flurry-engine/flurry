package uk.aidanlee.flurry.api.input;

import haxe.EnumFlags;
import uk.aidanlee.flurry.api.input.Types.KeyModifier;
import uk.aidanlee.flurry.api.input.Types.TextEventType;
import uk.aidanlee.flurry.api.input.Types.GamepadDeviceEventType;
import rx.Subject;

class InputEvents
{
    public final keyUp : Subject<InputEventKeyState>;

    public final keyDown : Subject<InputEventKeyState>;

    public final textInput : Subject<InputEventTextInput>;

    public final mouseUp : Subject<InputEventMouseState>;

    public final mouseDown : Subject<InputEventMouseState>;

    public final mouseWheel : Subject<InputEventMouseWheel>;

    public final mouseMove : Subject<InputEventMouseMove>;

    public final gamepadUp : Subject<InputEventGamepadState>;

    public final gamepadDown : Subject<InputEventGamepadState>;

    public final gamepadAxis : Subject<InputEventGamepadAxis>;

    public final gamepadDevice : Subject<InputEventGamepadDevice>;
    
    public final gamepadRumble : Subject<InputEventGamepadRumble>;

    public function new()
    {
        keyUp         = new Subject();
        keyDown       = new Subject();
        textInput     = new Subject();
        mouseUp       = new Subject();
        mouseDown     = new Subject();
        mouseWheel    = new Subject();
        mouseMove     = new Subject();
        gamepadUp     = new Subject();
        gamepadDown   = new Subject();
        gamepadAxis   = new Subject();
        gamepadDevice = new Subject();
        gamepadRumble = new Subject();
    }
}

class InputEventKeyState
{
    public final keycode : Int;

    public final scancode : Int;

    public final repeat : Bool;

    public final modifier : EnumFlags<KeyModifier>;

    public function new(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : EnumFlags<KeyModifier>)
    {
        keycode   = _keycode;
        scancode  = _scancode;
        repeat    = _repeat;
        modifier  = _mod;
    }
}

class InputEventTextInput
{
    public final text : String;

    public final start : Int;

    public final length : Int;

    public final type : TextEventType;

    public function new(_text : String, _start : Int, _length : Int, _type : TextEventType)
    {
        text   = _text;
        start  = _start;
        length = _length;
        type   = _type;
    }
}

class InputEventMouseState
{
    public final x : Int;

    public final y : Int;

    public final button : Int;

    public function new(_x : Int, _y : Int, _button : Int)
    {
        x      = _x;
        y      = _y;
        button = _button;
    }
}

class InputEventMouseMove
{
    public final x : Int;

    public final y : Int;

    public final xRel : Int;

    public final yRel : Int;

    public function new(_x : Int, _y : Int, _xRel : Int, _yRel : Int)
    {
        x    = _x;
        y    = _y;
        xRel = _xRel;
        yRel = _yRel;
    }
}

class InputEventMouseWheel
{
    public final xWheelChange : Float;

    public final yWheelChange : Float;

    public function new(_x : Float, _y : Float)
    {
        xWheelChange = _x;
        yWheelChange = _y;
    }
}

class InputEventGamepadState
{
    public final gamepad : Int;

    public final button : Int;

    public final value : Float;

    public function new(_gamepad : Int, _button : Int, _value : Float)
    {
        gamepad = _gamepad;
        button  = _button;
        value   = _value;
    }
}

class InputEventGamepadRumble
{
    public final gamepad : Int;

    public final intensity : Float;

    public final duration : Int;

    public function new(_gamepad : Int, _intensity : Float, _duration : Int)
    {
        gamepad   = _gamepad;
        intensity = _intensity;
        duration  = _duration;
    }
}

class InputEventGamepadAxis
{
    public final gamepad : Int;

    public final axis : Int;

    public final value : Float;

    public function new(_gamepad : Int, _axis : Int, _value : Float)
    {
        gamepad = _gamepad;
        axis    = _axis;
        value   = _value;
    }
}

class InputEventGamepadDevice
{
    public final gamepad : Int;

    public final id : String;

    public final type : GamepadDeviceEventType;

    public function new(_gamepad : Int, _id : String, _type : GamepadDeviceEventType)
    {
        gamepad = _gamepad;
        id      = _id;
        type    = _type;
    }
}
