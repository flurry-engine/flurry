package uk.aidanlee.flurry.api.input;

class Input
{
    final events : EventBus;

    public function new(_events : EventBus)
    {
        events = _events;
    }

    // #region polling commands

    public function isKeyDown(_key : Int) : Bool
    {
        return false;
    }

    public function wasKeyPressed(_key : Int) : Bool
    {
        return false;
    }

    public function wasKeyReleased(_key : Int) : Bool
    {
        return false;
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

    // #endregion

    // #region user defined inputs

    // 

    // #endregion
}
