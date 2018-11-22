package uk.aidanlee.flurry.api.input;

import uk.aidanlee.flurry.api.input.InputEvents;

class Input
{
    final events : EventBus;

    final keyCodesPressed  : Map<Int, Bool>;
    final keyCodesReleased : Map<Int, Bool>;
    final keyCodesDown     : Map<Int, Bool>;

    final evKeyUp         : Int;
    final evKeyDown       : Int;
    final evMouseUp       : Int;
    final evMouseDown     : Int;
    final evGamepadDevice : Int;
    final evGamepadUp     : Int;
    final evGamepadDown   : Int;
    final evGamepadAxis   : Int;

    public function new(_events : EventBus)
    {
        events = _events;

        keyCodesPressed  = [];
        keyCodesReleased = [];
        keyCodesDown     = [];

        evKeyUp         = events.listen(InputEvents.KeyUp        , onKeyUp);
        evKeyDown       = events.listen(InputEvents.KeyDown      , onKeyDown);
        evMouseUp       = events.listen(InputEvents.MouseUp      , onMouseUp);
        evMouseDown     = events.listen(InputEvents.MouseDown    , onMouseDown);
        evGamepadDevice = events.listen(InputEvents.GamepadDevice, onGamepadDevice);
        evGamepadUp     = events.listen(InputEvents.GamepadUp    , onGamepadUp);
        evGamepadDown   = events.listen(InputEvents.GamepadDown  , onGamepadDown);
        evGamepadAxis   = events.listen(InputEvents.GamepadAxis  , onGamepadAxis);
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
        return false;
    } 

    public function wasMousePressed(_button : Int) : Bool
    {
        return false;
    }

    public function wasMouseReleased(_button : Int) : Bool
    {
        return false;
    }

    public function gamepadAxis(_gamepad : Int, _axis : Int) : Float
    {
        return 0;
    }

    public function isGamepadDown(_gamepad : Int, _button : Int) : Bool
    {
        return false;
    }

    public function wasGamepadPressed(_gamepad : Int, _button : Int) : Bool
    {
        return false;
    }

    public function wasGamepadReleased(_gamepad : Int, _button : Int) : Bool
    {
        return false;
    }

    public function update()
    {
        updateKeystate();
    }

    // #endregion

    // #region user defined inputs

    // 

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
        //
    }

    function onMouseDown(_event : InputEventMouseDown)
    {
        //
    }

    function onGamepadDevice(_event : InputEventGamepadDevice)
    {
        //
    }

    function onGamepadUp(_event : InputEventGamepadUp)
    {
        //
    }

    function onGamepadDown(_event : InputEventGamepadDown)
    {
        //
    }

    function onGamepadAxis(_event : InputEventGamepadAxis)
    {
        //
    }

    function updateKeystate()
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

    // #endregion
}
