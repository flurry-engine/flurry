package uk.aidanlee.flurry.api.input;

import snow.types.Types.ModState;
import snow.types.Types.TextEventType;
import snow.types.Types.GamepadDeviceEventType;

class InputEventKeyUp
{
    public final keycode : Int;

    public final scancode : Int;

    public final repeat : Bool;

    public final modifier : ModState;

    public function new(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState)
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

    public final modifier : ModState;

    public function new(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState)
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
