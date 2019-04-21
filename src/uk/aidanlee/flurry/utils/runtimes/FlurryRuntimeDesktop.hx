package uk.aidanlee.flurry.utils.runtimes;

import haxe.EnumFlags;
import sdl.Haptic;
import sdl.SDL;
import sdl.Window;
import snow.Snow;
import snow.api.Debug.*;
import snow.types.Types.WindowEventType;
import snow.types.Types.Error;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.input.Types.KeyModifier;

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

        flurry.events.input.gamepadRumble.add(onRumbleRequest);
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
        flurry.events.input.gamepadRumble.remove(onRumbleRequest);

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
                flurry.events.input.keyUp.dispatch(new InputEventKeyUp(
                    _event.key.keysym.sym,
                    _event.key.keysym.scancode,
                    _event.key.repeat,
                    toKeyMod(_event.key.keysym.mod)
                ));

            case SDL_KEYDOWN:
                flurry.events.input.keyDown.dispatch(new InputEventKeyDown(
                    _event.key.keysym.sym,
                    _event.key.keysym.scancode,
                    _event.key.repeat,
                    toKeyMod(_event.key.keysym.mod)
                ));

            case SDL_TEXTEDITING:
                flurry.events.input.textInput.dispatch(new InputEventTextInput(
                    _event.edit.text,
                    _event.edit.start,
                    _event.edit.length,
                    Edit
                ));

            case SDL_TEXTINPUT:
                flurry.events.input.textInput.dispatch(new InputEventTextInput(
                    _event.edit.text,
                    0,
                    0,
                    Edit
                ));

            case SDL_MOUSEMOTION:
                flurry.events.input.mouseMove.dispatch(new InputEventMouseMove(
                    _event.motion.x,
                    _event.motion.y,
                    _event.motion.xrel,
                    _event.motion.yrel
                ));

            case SDL_MOUSEBUTTONUP:
                flurry.events.input.mouseUp.dispatch(new InputEventMouseUp(_event.button.x, _event.button.y,  _event.button.button));

            case SDL_MOUSEBUTTONDOWN:
                flurry.events.input.mouseDown.dispatch(new InputEventMouseDown(_event.button.x, _event.button.y,  _event.button.button));

            case SDL_MOUSEWHEEL:
                flurry.events.input.mouseWheel.dispatch(new InputEventMouseWheel(_event.wheel.x, _event.wheel.y));

            case SDL_JOYAXISMOTION:

                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                //(range: -32768 to 32767)
                var val = (_event.jaxis.value + 32768) / (32767 + 32768);
                var normalized_val = (-0.5 + val) * 2.0;

                flurry.events.input.gamepadAxis.dispatch(new InputEventGamepadAxis(gp.slot, _event.jaxis.axis, normalized_val));

            case SDL_JOYBUTTONUP:
                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                flurry.events.input.gamepadUp.dispatch(new InputEventGamepadUp(gp.slot, _event.jbutton.button, 0));

            case SDL_JOYBUTTONDOWN:
                var gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                flurry.events.input.gamepadDown.dispatch(new InputEventGamepadDown(gp.slot, _event.jbutton.button, 1));

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

                flurry.events.input.gamepadDevice.dispatch(new InputEventGamepadDevice(
                    gp.slot,
                    SDL.gameControllerNameForIndex(_event.jdevice.which),
                    DeviceRemoved
                ));

            case SDL_CONTROLLERAXISMOTION:
                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                //(range: -32768 to 32767)
                var val = (_event.caxis.value + 32768) / (32767 + 32768);
                var normalized_val = (-0.5 + val) * 2.0;

                flurry.events.input.gamepadAxis.dispatch(new InputEventGamepadAxis(gp.slot, _event.caxis.axis, normalized_val));

            case SDL_CONTROLLERBUTTONUP:

                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                flurry.events.input.gamepadUp.dispatch(new InputEventGamepadUp(gp.slot, _event.cbutton.button, 0));

            case SDL_CONTROLLERBUTTONDOWN:

                var gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                flurry.events.input.gamepadDown.dispatch(new InputEventGamepadDown(gp.slot, _event.cbutton.button, 1));

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

                flurry.events.input.gamepadDevice.dispatch(new InputEventGamepadDevice(
                    gp.slot,
                    SDL.gameControllerNameForIndex(gp.instanceID),
                    DeviceRemoved
                ));

            case _:
                //
        }
    }

    function dispatchEventWindow(_event : sdl.Event)
    {
        if (_event.type == SDL_WINDOWEVENT)
        {
            switch (_event.window.event)
            {
                case SDL_WINDOWEVENT_SHOWN:
                    flurry.events.display.shown.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_HIDDEN:
                    flurry.events.display.hidden.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_EXPOSED:
                    flurry.events.display.exposed.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_MOVED:
                    flurry.events.display.moved.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_MINIMIZED:
                    flurry.events.display.minimised.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_MAXIMIZED:
                    flurry.events.display.maximised.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_RESTORED:
                    flurry.events.display.restored.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_ENTER:
                    flurry.events.display.enter.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_LEAVE:
                    flurry.events.display.leave.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_FOCUS_GAINED:
                    flurry.events.display.focusGained.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_FOCUS_LOST:
                    flurry.events.display.focusLost.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_CLOSE:
                    flurry.events.display.close.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_RESIZED:
                    flurry.events.display.resized.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    flurry.events.display.sizeChanged.dispatch(new DisplayEventData(_event.window.data1, _event.window.data2));

                case _:
            }
        }
    }

    function toKeyMod(_mod : Int) : EnumFlags<KeyModifier>
    {
        var flags = new EnumFlags();

        if (_mod == KMOD_NONE) flags.set(None);

        if (_mod == KMOD_LSHIFT) flags.set(LeftShift);
        if (_mod == KMOD_RSHIFT) flags.set(RightShift);
        if (_mod == KMOD_LCTRL)  flags.set(LeftControl);
        if (_mod == KMOD_RCTRL)  flags.set(RightControl);
        if (_mod == KMOD_LALT)   flags.set(LeftAlt);
        if (_mod == KMOD_RALT)   flags.set(RightAlt);
        if (_mod == KMOD_LGUI)   flags.set(LeftMeta);
        if (_mod == KMOD_RGUI)   flags.set(RightMeta);

        if (_mod == KMOD_NUM)    flags.set(NumLock);
        if (_mod == KMOD_CAPS)   flags.set(CapsLock);
        if (_mod == KMOD_MODE)   flags.set(Mode);

        if (_mod == KMOD_CTRL  || _mod == KMOD_LCTRL  || _mod == KMOD_RCTRL)  flags.set(Control);
        if (_mod == KMOD_SHIFT || _mod == KMOD_LSHIFT || _mod == KMOD_RSHIFT) flags.set(Shift);
        if (_mod == KMOD_ALT   || _mod == KMOD_LALT   || _mod == KMOD_RALT)   flags.set(Alt);
        if (_mod == KMOD_GUI   || _mod == KMOD_LGUI   || _mod == KMOD_RGUI)   flags.set(Meta);

        return flags;
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

                flurry.events.input.gamepadDevice.dispatch(new InputEventGamepadDevice(
                    slot,
                    SDL.gameControllerNameForIndex(_deviceIndex),
                    DeviceAdded
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

                flurry.events.input.gamepadDevice.dispatch(new InputEventGamepadDevice(
                    slot,
                    SDL.gameControllerNameForIndex(_deviceIndex),
                    DeviceAdded
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
