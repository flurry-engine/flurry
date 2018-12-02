package uk.aidanlee.flurry.utils.runtimes;

import sdl.Haptic;
import sdl.SDL;
import sdl.Window;
import snow.Snow;
import snow.api.Debug.*;
import snow.types.Types.WindowEventType;
import snow.types.Types.TextEventType;
import snow.types.Types.ModState;
import snow.types.Types.Error;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.input.InputEvents;

typedef RuntimeConfig = {}
typedef WindowHandle  = Window;

class FlurryRuntimeDesktop extends snow.core.native.Runtime
{
    /**
     * Access to the flurry host.
     * Used to fire events into the main bus and check if the app has loaded.
     */
    final flurry : Flurry;

    final gamepadSlots : Array<Gamepad>;

    final gamepadInstanceSlotMapping : Map<Int, Gamepad>;

    public function new(_app : Snow)
    {
        super(_app);

        flurry = app.host;
        gamepadSlots = [];
        gamepadInstanceSlotMapping = [];

        if (SDL.init(SDL_INIT_TIMER) != 0)
        {
            throw Error.init('runtime / flurry / failed to init / ${SDL.getError()}');
        }

        #if !flurry_sdl_no_video

        if (SDL.initSubSystem(SDL_INIT_VIDEO) != 0)
        {
            throw Error.init('runtime / flurry / failed to initialize video / ${SDL.getError()}');
        }
        else
        {
            _debug('sdl / init video');
        }

        #end

        #if !flurry_sdl_no_gamepads

        if (SDL.initSubSystem(SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER | SDL_INIT_HAPTIC) != 0)
        {
            throw Error.init('runtime / flurry / failed to initialize joystick, game controllers, and haptic / ${SDL.getError()}');
        }
        else
        {
            for (i in 0...SDL.numJoysticks())
            {
                if (SDL.isGameController(i))
                {
                    setupNewGameController(i);
                }
                else
                {
                    setupNewJoystick(i);
                }
            }

            _debug('sdl / init gamepads');
        }

        #end

        _debug('sdl / init ok');

        flurry.events.listen(GamepadRumble, onRumbleRequest);
    }

    public static function timestamp() : Float
    {
        return haxe.Timer.stamp();
    }

    override public function ready()
    {
        _debug('sdl / ready');
    }

    override public function run() : Bool
    {
        _debug('sdl / run');

        return runLoop();
    }

    override public function shutdown(?_immediate : Bool = false)
    {
        if (_immediate)
        {
            _debug('sdl / shutdown immediate');
        }
        else
        {
            SDL.quit();
            
            _debug('sdl / shutdown');
        }
    }

    function runLoop() : Bool
    {
        _debug('sdl / running main loop');

        while (!app.shutting_down)
        {
            loop();
        }

        return true;
    }

    function loop()
    {
        while (SDL.hasAnEvent())
        {
            var event = SDL.pollEvent();
            if (event.type == SDL_QUIT)
            {
                app.dispatch_event(se_quit);
            }
            else
            {
                if (flurry.isLoaded())
                {
                    dispatchEventInput(event);
                    dispatchEventWindow(event);
                }
            }
        }

        app.dispatch_event(se_tick);
    }

    function dispatchEventInput(_event : sdl.Event)
    {
        switch (_event.type) {
            case SDL_KEYUP:

                #if !flurry_no_snow_input_events
                    app.input.dispatch_key_up_event(
                        _event.key.keysym.sym,
                        _event.key.keysym.scancode,
                        _event.key.repeat,
                        toKeyMod(_event.key.keysym.mod),
                        _event.key.timestamp / 1000,
                        _event.key.windowID
                    );
                #end

                flurry.events.fire(InputEvents.KeyUp, new InputEventKeyUp(
                    _event.key.keysym.sym,
                    _event.key.keysym.scancode,
                    _event.key.repeat,
                    toKeyMod(_event.key.keysym.mod)
                ));

            case SDL_KEYDOWN:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_key_down_event(
                        _event.key.keysym.sym,
                        _event.key.keysym.scancode,
                        _event.key.repeat,
                        toKeyMod(_event.key.keysym.mod),
                        _event.key.timestamp / 1000,
                        _event.key.windowID
                    );
                #end

                flurry.events.fire(InputEvents.KeyDown, new InputEventKeyDown(
                    _event.key.keysym.sym,
                    _event.key.keysym.scancode,
                    _event.key.repeat,
                    toKeyMod(_event.key.keysym.mod)
                ));

            case SDL_TEXTEDITING:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_text_event(
                        _event.edit.text,
                        _event.edit.start,
                        _event.edit.length,
                        TextEventType.te_edit,
                        _event.edit.timestamp / 1000,
                        _event.edit.windowID
                    );
                #end

                flurry.events.fire(InputEvents.TextInput, new InputEventTextInput(
                    _event.edit.text,
                    _event.edit.start,
                    _event.edit.length,
                    TextEventType.te_edit
                ));

            case SDL_TEXTINPUT:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_text_event(
                        _event.edit.text,
                        0,
                        0,
                        TextEventType.te_input,
                        _event.edit.timestamp / 1000,
                        _event.edit.windowID
                    );
                #end

                flurry.events.fire(InputEvents.TextInput, new InputEventTextInput(
                    _event.edit.text,
                    0,
                    0,
                    TextEventType.te_input
                ));

            case SDL_MOUSEMOTION:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_mouse_move_event(
                        _event.motion.x,
                        _event.motion.y,
                        _event.motion.xrel,
                        _event.motion.yrel,
                        _event.motion.timestamp / 1000,
                        _event.motion.windowID
                    );
                #end

                flurry.events.fire(InputEvents.MouseMove, new InputEventMouseMove(
                    _event.motion.x,
                    _event.motion.y,
                    _event.motion.xrel,
                    _event.motion.yrel
                ));

            case SDL_MOUSEBUTTONUP:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_mouse_up_event(
                        _event.button.x,
                        _event.button.y,
                        _event.button.button,
                        _event.button.timestamp / 1000,
                        _event.button.windowID
                    );
                #end

                flurry.events.fire(InputEvents.MouseUp, new InputEventMouseUp(_event.button.x, _event.button.y,  _event.button.button));

            case SDL_MOUSEBUTTONDOWN:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_mouse_down_event(
                        _event.button.x,
                        _event.button.y,
                        _event.button.button,
                        _event.button.timestamp / 1000,
                        _event.button.windowID
                    );
                #end

                flurry.events.fire(InputEvents.MouseDown, new InputEventMouseDown(_event.button.x, _event.button.y,  _event.button.button));

            case SDL_MOUSEWHEEL:
                #if !flurry_no_snow_input_events
                    app.input.dispatch_mouse_wheel_event(
                        _event.wheel.x,
                        _event.wheel.y,
                        _event.wheel.timestamp / 1000,
                        _event.wheel.windowID
                    );
                #end

                flurry.events.fire(InputEvents.MouseWheel, new InputEventMouseWheel(_event.wheel.x, _event.wheel.y));

            case SDL_JOYAXISMOTION:

                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                //(range: -32768 to 32767)
                var val = (_event.jaxis.value + 32768) / (32767 + 32768);
                var normalized_val = (-0.5 + val) * 2.0;

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_axis_event(
                        gp.slot,
                        _event.jaxis.axis,
                        normalized_val,
                        _event.jaxis.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadAxis, new InputEventGamepadAxis(gp.slot, _event.jaxis.axis, normalized_val));

            case SDL_JOYBUTTONUP:

                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_button_up_event(
                        gp.slot,
                        _event.jbutton.button,
                        0,
                        _event.jbutton.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadUp, new InputEventGamepadUp(gp.slot, _event.jbutton.button, 0));

            case SDL_JOYBUTTONDOWN:

                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_button_down_event(
                        gp.slot,
                        _event.jbutton.button,
                        1,
                        _event.jbutton.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadDown, new InputEventGamepadDown(gp.slot, _event.jbutton.button, 1));

            case SDL_JOYDEVICEADDED:

                if (SDL.isGameController(_event.jdevice.which))
                {
                    return;
                }

                setupNewJoystick(_event.jdevice.which);

            case SDL_JOYDEVICEREMOVED:
                if (!gamepadInstanceSlotMapping.exists(_event.jdevice.which))
                {
                    return;
                }

                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];
                if (!gp.isJoystick)
                {
                    return;
                }

                gamepadInstanceSlotMapping.remove(_event.jdevice.which);
                gamepadSlots[gp.slot] = null;

                SDL.hapticRumbleStop(gp.haptic);
                SDL.hapticClose(gp.haptic);

                _debug('sdl / removed joystick ${_event.jdevice.which} from slot ${gp.slot}');

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_device_event(
                        gp.slot,
                        SDL.gameControllerNameForIndex(_event.jdevice.which),
                        ge_device_removed,
                        _event.jdevice.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadDevice, new InputEventGamepadDevice(
                    gp.slot,
                    SDL.gameControllerNameForIndex(_event.jdevice.which),
                    ge_device_removed
                ));

            case SDL_CONTROLLERAXISMOTION:
                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                //(range: -32768 to 32767)
                var val = (_event.caxis.value + 32768) / (32767 + 32768);
                var normalized_val = (-0.5 + val) * 2.0;

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_axis_event(
                        gp.slot,
                        _event.caxis.axis,
                        normalized_val,
                        _event.caxis.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadAxis, new InputEventGamepadAxis(gp.slot, _event.caxis.axis, normalized_val));

            case SDL_CONTROLLERBUTTONUP:

                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_button_up_event(
                        gp.slot,
                        _event.cbutton.button,
                        0,
                        _event.cbutton.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadUp, new InputEventGamepadUp(gp.slot, _event.cbutton.button, 0));

            case SDL_CONTROLLERBUTTONDOWN:

                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_button_down_event(
                        gp.slot,
                        _event.cbutton.button,
                        1,
                        _event.cbutton.timestamp / 1000
                    );
                #end

                flurry.events.fire(InputEvents.GamepadDown, new InputEventGamepadDown(gp.slot, _event.cbutton.button, 1));

            case SDL_CONTROLLERDEVICEADDED:
                setupNewGameController(_event.cdevice.which);

            case SDL_CONTROLLERDEVICEREMOVED:
                if (!gamepadInstanceSlotMapping.exists(_event.cdevice.which))
                {
                    return;
                }

                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];
                gamepadInstanceSlotMapping.remove(gp.instanceID);
                gamepadSlots[gp.slot] = null;

                SDL.hapticRumbleStop(gp.haptic);
                SDL.hapticClose(gp.haptic);

                _debug('sdl / removed game controller ${gp.instanceID} from slot ${gp.slot}');

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_device_event(
                        gp.slot,
                        SDL.gameControllerNameForIndex(gp.instanceID),
                        ge_device_removed,
                        0
                    );
                #end

                flurry.events.fire(InputEvents.GamepadDevice, new InputEventGamepadDevice(
                    gp.slot,
                    SDL.gameControllerNameForIndex(gp.instanceID),
                    ge_device_removed
                ));

            case _:
                //
        }
    }

    function dispatchEventWindow(_event : sdl.Event)
    {
        if (_event.type == SDL_WINDOWEVENT)
        {
            var snowType   = WindowEventType.we_unknown;
            var flurryType = DisplayEvents.Unknown;

            switch (_event.window.event)
            {
                case SDL_WINDOWEVENT_SHOWN:
                    snowType   = we_shown;
                    flurryType = Shown;

                case SDL_WINDOWEVENT_HIDDEN:
                    snowType   = we_hidden;
                    flurryType = Hidden;

                case SDL_WINDOWEVENT_EXPOSED:
                    snowType   = we_exposed;
                    flurryType = Exposed;

                case SDL_WINDOWEVENT_MOVED:
                    snowType   = we_moved;
                    flurryType = Moved;

                case SDL_WINDOWEVENT_MINIMIZED:
                    snowType   = we_minimized;
                    flurryType = Minimised;

                case SDL_WINDOWEVENT_MAXIMIZED:
                    snowType   = we_maximized;
                    flurryType = Maximised;

                case SDL_WINDOWEVENT_RESTORED:
                    snowType   = we_restored;
                    flurryType = Restored;

                case SDL_WINDOWEVENT_ENTER:
                    snowType   = we_enter;
                    flurryType = Enter;

                case SDL_WINDOWEVENT_LEAVE:
                    snowType   = we_leave;
                    flurryType = Leave;

                case SDL_WINDOWEVENT_FOCUS_GAINED:
                    snowType   = we_focus_gained;
                    flurryType = FocusGained;

                case SDL_WINDOWEVENT_FOCUS_LOST:
                    snowType   = we_focus_lost;
                    flurryType = FocusLost;

                case SDL_WINDOWEVENT_CLOSE:
                    snowType   = we_close;
                    flurryType = Close;

                case SDL_WINDOWEVENT_RESIZED:
                    snowType   = we_resized;
                    flurryType = Resized;

                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    snowType   = we_size_changed;
                    flurryType = SizeChanged;

                case _:
            }

            #if !flurry_no_snow_window_events
                if (snowType != we_unknown)
                {
                    app.dispatch_window_event(
                        snowType,
                        _event.window.timestamp / 1000,
                        _event.window.windowID,
                        _event.window.data1,
                        _event.window.data2
                    );
                }
            #end

            if (flurryType != Unknown)
            {
                flurry.events.fire(flurryType, new DisplayEventData(_event.window.data1, _event.window.data2));
            }
        }
    }

    function toKeyMod(_mod : Int) : ModState
    {
        app.input.mod_state.none    = _mod == KMOD_NONE;

        app.input.mod_state.lshift  = _mod == KMOD_LSHIFT;
        app.input.mod_state.rshift  = _mod == KMOD_RSHIFT;
        app.input.mod_state.lctrl   = _mod == KMOD_LCTRL;
        app.input.mod_state.rctrl   = _mod == KMOD_RCTRL;
        app.input.mod_state.lalt    = _mod == KMOD_LALT;
        app.input.mod_state.ralt    = _mod == KMOD_RALT;
        app.input.mod_state.lmeta   = _mod == KMOD_LGUI;
        app.input.mod_state.rmeta   = _mod == KMOD_RGUI;

        app.input.mod_state.num     = _mod == KMOD_NUM;
        app.input.mod_state.caps    = _mod == KMOD_CAPS;
        app.input.mod_state.mode    = _mod == KMOD_MODE;

        app.input.mod_state.ctrl    = (_mod == KMOD_CTRL  || _mod == KMOD_LCTRL  || _mod == KMOD_RCTRL);
        app.input.mod_state.shift   = (_mod == KMOD_SHIFT || _mod == KMOD_LSHIFT || _mod == KMOD_RSHIFT);
        app.input.mod_state.alt     = (_mod == KMOD_ALT   || _mod == KMOD_LALT   || _mod == KMOD_RALT);
        app.input.mod_state.meta    = (_mod == KMOD_GUI   || _mod == KMOD_LGUI   || _mod == KMOD_RGUI);

        return app.input.mod_state;
    }

    function getFirstFreeGamepadSlot() : Int
    {
        for (i in 0...gamepadSlots.length)
        {
            if (gamepadSlots[i] == null)
            {
                return i;
            }
        }

        gamepadSlots.push(null);

        return gamepadSlots.length - 1;
    }

    function setupNewJoystick(_deviceIndex : Int)
    {
        var js = SDL.joystickOpen(_deviceIndex);
        if (js == null)
        {
            _debug('sdl / unable to open joystick ${SDL.getError()}');
        }
        else
        {
            var jsID = SDL.joystickInstanceID(js);
            var slot = getFirstFreeGamepadSlot();

            if (slot != -1)
            {
                var haptic = SDL.hapticOpenFromJoystick(js);
                if (haptic == null)
                {
                    _debug('sdl / joystick does not support haptics');
                }

                if (haptic != null && SDL.hapticRumbleInit(haptic) != 0)
                {
                    _debug('sdl / could not init rumble haptics ${SDL.getError()}');
                }

                var gp = new Gamepad(true, haptic, slot, jsID);

                gamepadSlots[slot] = gp;
                gamepadInstanceSlotMapping[jsID] = gp;

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_device_event(
                        slot,
                        SDL.gameControllerNameForIndex(_deviceIndex),
                        ge_device_added,
                        0
                    );
                #end

                flurry.events.fire(InputEvents.GamepadDevice, new InputEventGamepadDevice(
                    slot,
                    SDL.gameControllerNameForIndex(_deviceIndex),
                    ge_device_added
                ));

                _debug('sdl / added joystick $jsID to slot $slot');
            }
            else
            {
                _debug('sdl / unable to add joystick $jsID, no more slots');
            }
        }
    }

    function setupNewGameController(_deviceIndex : Int)
    {
        var gc = SDL.gameControllerOpen(_deviceIndex);
        if (gc == null)
        {
            _debug('sdl / unable to open game controller $_deviceIndex, ${SDL.getError()}');
        }
        else
        {
            var jsID = SDL.joystickInstanceID(SDL.gameControllerGetJoystick(gc));
            var slot = getFirstFreeGamepadSlot();

            if (slot != -1)
            {
                var haptic = SDL.hapticOpenFromJoystick(SDL.gameControllerGetJoystick(gc));
                if (haptic == null)
                {
                    _debug('sdl / joystick does not support haptics ${SDL.getError()}');
                }

                if (haptic != null && SDL.hapticRumbleInit(haptic) != 0)
                {
                    _debug('sdl / could not init rumble haptics ${SDL.getError()}');
                }

                var gp = new Gamepad(false, haptic, slot, jsID);

                gamepadSlots[slot] = gp;
                gamepadInstanceSlotMapping[jsID] = gp;

                #if !flurry_no_snow_input_events
                    app.input.dispatch_gamepad_device_event(
                        slot,
                        SDL.gameControllerNameForIndex(_deviceIndex),
                        ge_device_added,
                        0
                    );
                #end

                flurry.events.fire(InputEvents.GamepadDevice, new InputEventGamepadDevice(
                    slot,
                    SDL.gameControllerNameForIndex(_deviceIndex),
                    ge_device_added
                ));

                _debug('sdl / added game controller $jsID to slot ${gp.slot}');
            }
            else
            {
                _debug('sdl / unable to add game controller $jsID, no more slots');
            }
        }
    }

    function onRumbleRequest(_event : InputEventGamepadRumble)
    {
        if (_event.gamepad >= gamepadSlots.length)
        {
            return;
        }

        var gp = gamepadSlots[_event.gamepad];
        if (gp.haptic != null)
        {
            if (SDL.hapticRumblePlay(gp.haptic, _event.intensity, _event.duration) != 0)
            {
                _debug('sdl / unable to play rumble haptic ${SDL.getError()}');
            }
        }
    }
}

private class Gamepad
{
    public final isJoystick : Bool;

    public final haptic : Haptic;

    public final slot : Int;

    public final instanceID : Int;

    public function new(_isJoystick : Bool, _haptic : Haptic, _slot : Int, _instanceID : Int)
    {
        isJoystick = _isJoystick;
        haptic     = _haptic;
        slot       = _slot;
        instanceID = _instanceID;
    }
}
