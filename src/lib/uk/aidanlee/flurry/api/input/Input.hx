package uk.aidanlee.flurry.api.input;

import hxrx.observer.Observer;
import uk.aidanlee.flurry.api.input.InputEvents;

private enum InputState
{
    None;
    Pressed;
    Held;
    Released;
}

class Input
{
    static final MAX_KEYS = 300;
    static final MAX_MOUSE_BUTTONS = 32;
    static final MAX_CONTROLLERS = 8;
    static final MAX_CONTROLLER_BUTTONS = 32;
    static final MAX_CONTROLLER_AXISES = 32;

    final events : InputEvents;

    final scancodes : Array<InputState>;

    final mouseButtons : Array<InputState>;

    final gamepadButtons : Array<Array<InputState>>;

    final gamepadAxises : Array<Array<Float>>;

    public function new(_events : InputEvents)
    {
        events = _events;

        scancodes      = [ for (_ in 0...MAX_KEYS) None ];
        mouseButtons   = [ for (_ in 0...MAX_MOUSE_BUTTONS) None ];
        gamepadButtons = [ for (_ in 0...MAX_CONTROLLERS) [ for (_ in 0...MAX_CONTROLLER_BUTTONS) None ] ];
        gamepadAxises  = [ for (_ in 0...MAX_CONTROLLERS) [ for (_ in 0...MAX_CONTROLLER_AXISES) 0 ] ];

        events.keyUp.subscribe(new Observer(onKeyUp, null, null));
        events.keyDown.subscribe(new Observer(onKeyDown, null, null));
        events.mouseUp.subscribe(new Observer(onMouseUp, null, null));
        events.mouseDown.subscribe(new Observer(onMouseDown, null, null));
        events.gamepadUp.subscribe(new Observer(onGamepadUp, null, null));
        events.gamepadDown.subscribe(new Observer(onGamepadDown, null, null));
        events.gamepadAxis.subscribe(new Observer(onGamepadAxis, null, null));
    }

    // #region polling commands

    public function isKeyDown(_key : Int) : Bool
    {
        return scancodes[Keycodes.toScan(_key)] == Held || scancodes[Keycodes.toScan(_key)] == Pressed;
    }

    public function wasKeyPressed(_key : Int) : Bool
    {
        return scancodes[Keycodes.toScan(_key)] == Pressed;
    }

    public function wasKeyReleased(_key : Int) : Bool
    {
        return scancodes[Keycodes.toScan(_key)] == Released;
    }

    public function isMouseDown(_button : Int) : Bool
    {
        return mouseButtons[_button] == Held || mouseButtons[_button] == Pressed;
    } 

    public function wasMousePressed(_button : Int) : Bool
    {
        return mouseButtons[_button] == Pressed;
    }

    public function wasMouseReleased(_button : Int) : Bool
    {
        return mouseButtons[_button] == Released;
    }

    public function gamepadAxis(_gamepad : Int, _axis : Int) : Float
    {
        return gamepadAxises[_gamepad][_axis];
    }

    public function isGamepadDown(_gamepad : Int, _button : Int) : Bool
    {
        return gamepadButtons[_gamepad][_button] == Pressed || gamepadButtons[_gamepad][_button] == Held;
    }

    public function wasGamepadPressed(_gamepad : Int, _button : Int) : Bool
    {
        return gamepadButtons[_gamepad][_button] == Pressed;
    }

    public function wasGamepadReleased(_gamepad : Int, _button : Int) : Bool
    {
        return gamepadButtons[_gamepad][_button] == Released;
    }

    public function rumbleGamepad(_gamepad : Int, _intensity : Float, _duration : Int) : Void
    {
        events.gamepadRumble.onNext(new InputEventGamepadRumble(_gamepad, _intensity, _duration));
    }

    public function update()
    {
        updateKeyState();
        updateMouseState();
        updateGamepadState();
    }

    // #endregion

    // #region internals

    function onKeyUp(_event : InputEventKeyState)
    {
        scancodes[_event.scancode] = Released;
    }

    function onKeyDown(_event : InputEventKeyState)
    {
        if (!_event.repeat)
        {
            scancodes[_event.scancode] = Pressed;
        }
    }

    function onMouseUp(_event : InputEventMouseState)
    {
        mouseButtons[_event.button] = Released;
    }

    function onMouseDown(_event : InputEventMouseState)
    {
        mouseButtons[_event.button] = Pressed;
    }

    function onGamepadUp(_event : InputEventGamepadState)
    {
        gamepadButtons[_event.gamepad][_event.button] = Released;
    }

    function onGamepadDown(_event : InputEventGamepadState)
    {
        gamepadButtons[_event.gamepad][_event.button] = Pressed;
    }

    function onGamepadAxis(_event : InputEventGamepadAxis)
    {
        gamepadAxises[_event.gamepad][_event.axis] = _event.value;
    }

    function updateKeyState()
    {
        for (i in 0...scancodes.length)
        {
            switch (scancodes[i])
            {
                case Pressed  : scancodes[i] = Held;
                case Released : scancodes[i] = None;
                case _ :
            }
        }
    }

    function updateMouseState()
    {
        for (i in 0...mouseButtons.length)
        {
            switch (mouseButtons[i])
            {
                case Pressed  : mouseButtons[i] = Held;
                case Released : mouseButtons[i] = None;
                case _ :
            }
        }
    }

    function updateGamepadState()
    {
        for (i in 0...gamepadButtons.length)
        {
            for (j in 0...gamepadButtons[i].length)
            {
                switch (gamepadButtons[i][j]) {
                    case Pressed  : gamepadButtons[i][j] = Held;
                    case Released : gamepadButtons[i][j] = None;
                    case _ :
                }
            }
        }
    }

    // #endregion
}
