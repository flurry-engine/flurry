package uk.aidanlee.flurry.api.input;

import haxe.EnumFlags;
import uk.aidanlee.flurry.api.input.Types.KeyModifier;
import uk.aidanlee.flurry.api.input.Types.TextEventType;
import uk.aidanlee.flurry.api.input.Types.GamepadDeviceEventType;
import signal.Signal1;

class InputEvents
{
    public final keyUp : Signal1<InputEventKeyUp>;

    public final keyDown : Signal1<InputEventKeyDown>;

    public final textInput : Signal1<InputEventTextInput>;

    public final mouseUp : Signal1<InputEventMouseUp>;

    public final mouseDown : Signal1<InputEventMouseDown>;

    public final mouseWheel : Signal1<InputEventMouseWheel>;

    public final mouseMove : Signal1<InputEventMouseMove>;

    public final gamepadUp : Signal1<InputEventGamepadUp>;

    public final gamepadDown : Signal1<InputEventGamepadDown>;

    public final gamepadAxis : Signal1<InputEventGamepadAxis>;

    public final gamepadDevice : Signal1<InputEventGamepadDevice>;
    
    public final gamepadRumble : Signal1<InputEventGamepadRumble>;

    public function new()
    {
        keyUp         = new Signal1<InputEventKeyUp>();
        keyDown       = new Signal1<InputEventKeyDown>();
        textInput     = new Signal1<InputEventTextInput>();
        mouseUp       = new Signal1<InputEventMouseUp>();
        mouseDown     = new Signal1<InputEventMouseDown>();
        mouseWheel    = new Signal1<InputEventMouseWheel>();
        mouseMove     = new Signal1<InputEventMouseMove>();
        gamepadUp     = new Signal1<InputEventGamepadUp>();
        gamepadDown   = new Signal1<InputEventGamepadDown>();
        gamepadAxis   = new Signal1<InputEventGamepadAxis>();
        gamepadDevice = new Signal1<InputEventGamepadDevice>();
        gamepadRumble = new Signal1<InputEventGamepadRumble>();
    }
}

class InputEventKeyUp
{
    public final keycode : Int;

    public final scancode : Int;

    public final repeat : Bool;

    public final modifier : EnumFlags<KeyModifier>;

    public function new(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : EnumFlags<KeyModifier>)
    {
        keycode  = _keycode;
        scancode = _scancode;
        repeat   = _repeat;
        modifier = _mod;
    }
}

class InputEventKeyDown
{
    public final keycode : Int;

    public final scancode : Int;

    public final repeat : Bool;

    public final modifier : EnumFlags<KeyModifier>;

    public function new(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : EnumFlags<KeyModifier>)
    {
        keycode  = _keycode;
        scancode = _scancode;
        repeat   = _repeat;
        modifier = _mod;
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

class InputEventMouseUp
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

class InputEventMouseDown
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

class InputEventGamepadUp
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

class InputEventGamepadDown
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
