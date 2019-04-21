package uk.aidanlee.flurry.api.input;

import uk.aidanlee.flurry.api.input.InputEvents;

class Input
{
    public static final MAX_CONTROLLERS : Int = 8;

    final events : InputEvents;

    final keyCodesPressed  : Map<Int, Bool>;
    final keyCodesReleased : Map<Int, Bool>;
    final keyCodesDown     : Map<Int, Bool>;

    final mouseButtonsPressed  : Map<Int, Bool>;
    final mouseButtonsReleased : Map<Int, Bool>;
    final mouseButtonsDown     : Map<Int, Bool>;

    final gamepadButtonsPressed  : Array<Map<Int, Bool>>;
    final gamepadButtonsReleased : Array<Map<Int, Bool>>;
    final gamepadButtonsDown     : Array<Map<Int, Bool>>;
    final gamepadAxisValues      : Array<Map<Int, Float>>;

    public function new(_events : InputEvents)
    {
        events = _events;

        keyCodesPressed  = [];
        keyCodesReleased = [];
        keyCodesDown     = [];

        mouseButtonsPressed  = [];
        mouseButtonsReleased = [];
        mouseButtonsDown     = [];

        gamepadButtonsPressed  = [ for (i in 0...MAX_CONTROLLERS) [] ];
        gamepadButtonsReleased = [ for (i in 0...MAX_CONTROLLERS) [] ];
        gamepadButtonsDown     = [ for (i in 0...MAX_CONTROLLERS) [] ];
        gamepadAxisValues      = [ for (i in 0...MAX_CONTROLLERS) [] ];

        events.keyUp.add(onKeyUp);
        events.keyDown.add(onKeyDown);
        events.mouseUp.add(onMouseUp);
        events.mouseDown.add(onMouseDown);
        events.gamepadUp.add(onGamepadUp);
        events.gamepadDown.add(onGamepadDown);
        events.gamepadAxis.add(onGamepadAxis);
    }

    // #region polling commands

    public function isKeyDown(_key : Int) : Bool
    {
        return keyCodesDown.exists(_key);
    }

    public function wasKeyPressed(_key : Int) : Bool
    {
        return keyCodesPressed.exists(_key);
    }

    public function wasKeyReleased(_key : Int) : Bool
    {
        return keyCodesReleased.exists(_key);
    }

    public function isMouseDown(_button : Int) : Bool
    {
        return mouseButtonsDown.exists(_button);
    } 

    public function wasMousePressed(_button : Int) : Bool
    {
        return mouseButtonsPressed.exists(_button);
    }

    public function wasMouseReleased(_button : Int) : Bool
    {
        return mouseButtonsReleased.exists(_button);
    }

    public function gamepadAxis(_gamepad : Int, _axis : Int) : Float
    {
        if (gamepadAxisValues[_gamepad].exists(_axis))
        {
            if (gamepadAxisValues[_gamepad].exists(_axis))
            {
                return gamepadAxisValues[_gamepad].get(_axis);
            }

            return 0;
        }

        return 0;
    }

    public function isGamepadDown(_gamepad : Int, _button : Int) : Bool
    {
        return gamepadButtonsDown[_gamepad].exists(_button);
    }

    public function wasGamepadPressed(_gamepad : Int, _button : Int) : Bool
    {
        return gamepadButtonsPressed[_gamepad].exists(_button);
    }

    public function wasGamepadReleased(_gamepad : Int, _button : Int) : Bool
    {
        return gamepadButtonsReleased[_gamepad].exists(_button);
    }

    public function rumbleGamepad(_gamepad : Int, _intensity : Float, _duration : Int) : Void
    {
        events.gamepadRumble.dispatch(new InputEventGamepadRumble(_gamepad, _intensity, _duration));
    }

    public function update()
    {
        updateKeyState();
        updateMouseState();
        updateGamepadState();
    }

    // #endregion

    // #region internals

    function onKeyUp(_event : InputEventKeyUp)
    {
        keyCodesReleased.set(_event.keycode, false);
        keyCodesDown.remove(_event.keycode);
    }

    function onKeyDown(_event : InputEventKeyDown)
    {
        if (!_event.repeat)
        {
            keyCodesPressed.set(_event.keycode, false);
            keyCodesDown.set(_event.keycode, true);
        }
    }

    function onMouseUp(_event : InputEventMouseUp)
    {
        mouseButtonsReleased.set(_event.button, false);
        mouseButtonsDown.remove(_event.button);
    }

    function onMouseDown(_event : InputEventMouseDown)
    {
        mouseButtonsPressed.set(_event.button, false);
        mouseButtonsDown.set(_event.button, true);
    }

    function onGamepadUp(_event : InputEventGamepadUp)
    {
        gamepadButtonsReleased[_event.gamepad].set(_event.button, false);
        gamepadButtonsDown[_event.gamepad].remove(_event.button);
    }

    function onGamepadDown(_event : InputEventGamepadDown)
    {
        gamepadButtonsPressed[_event.gamepad].set(_event.button, false);
        gamepadButtonsDown[_event.gamepad].set(_event.button, true);
    }

    function onGamepadAxis(_event : InputEventGamepadAxis)
    {
        gamepadAxisValues[_event.gamepad].set(_event.axis, _event.value);
    }

    function updateKeyState()
    {
        for (key => state in keyCodesPressed)
        {
            if (state)
            {
                keyCodesPressed.remove(key);
            }
            else
            {
                keyCodesPressed.set(key, true);
            }
        }

        for (key => state in keyCodesReleased)
        {
            if (state)
            {
                keyCodesReleased.remove(key);
            }
            else
            {
                keyCodesReleased.set(key, true);
            }
        }
    }

    function updateMouseState()
    {
        for (button => state in mouseButtonsPressed)
        {
            if (state)
            {
                mouseButtonsPressed.remove(button);
            }
            else
            {
                mouseButtonsPressed.set(button, true);
            }
        }

        for (button => state in mouseButtonsReleased)
        {
            if (state)
            {
                mouseButtonsReleased.remove(button);
            }
            else
            {
                mouseButtonsReleased.set(button, true);
            }
        }
    }

    function updateGamepadState()
    {
        for (gamepad in gamepadButtonsPressed)
        {
            for (button => state in gamepad)
            {
                if (state)
                {
                    gamepad.remove(button);
                }
                else
                {
                    gamepad.set(button, true);
                }
            }
        }

        for (gamepad in gamepadButtonsReleased)
        {
            for (button => state in gamepad)
            {
                if (state)
                {
                    gamepad.remove(button);
                }
                else
                {
                    gamepad.set(button, true);
                }
            }
        }
    }

    // #endregion
}
