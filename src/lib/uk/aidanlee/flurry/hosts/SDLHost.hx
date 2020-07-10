package uk.aidanlee.flurry.hosts;

import haxe.Timer;
import haxe.EnumFlags;
import haxe.io.Path;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadRumble;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadDevice;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadState;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadAxis;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseWheel;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseState;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseMove;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventTextInput;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventKeyState;
import uk.aidanlee.flurry.api.input.Types.KeyModifier;
import uk.aidanlee.flurry.api.display.DisplayEvents.DisplayEventData;
import uk.aidanlee.flurry.macros.Host;
import sdl.SDL;
import sdl.Haptic;

/**
 * This class acts as the entry point when targetting desktops and drives the flurry application.
 * Calls the applications `update` at a fixed timestep and `tick` as often as possible.
 */
class SDLHost
{
    static function main()
    {
        new SDLHost();
    }

    /**
     * The users flurry application.
     * This is set by a macro by creating an instance of the class stored in the `flurry-entry-point` compiler define.
     */
    final flurry : Flurry;

    /**
     * The target frame rate of the program.
     * Not currently user definable.
     */
    final frameRate : Int;

    /**
     * Number of miliseconds between each frame.
     */
    final deltaTime : Float;

    final gamepadSlots : Array<Gamepad>;

    final gamepadInstanceSlotMapping : Map<Int, Gamepad>;

    var time : Float;

    var currentTime : Float;

    var accumulator : Float;

    function new()
    {
        if (SDL.init(SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER | SDL_INIT_HAPTIC) != 0)
        {
            throw 'failed to init SDL2';
        }

        // Important to set the working directory
        // Ensure we can use relative paths to read parcels.
        Sys.setCwd(Path.directory(Sys.programPath()));

        frameRate   = 60;
        deltaTime   = 1000 / frameRate;
        time        = 0;
        currentTime = Timer.stamp();
        accumulator = 0;

        gamepadSlots               = [];
        gamepadInstanceSlotMapping = [];

        flurry = Host.entry();
        flurry.config();
        flurry.ready();

        while (true)
        {
            final newTime   = Timer.stamp() * 1000;
            final frameTime = newTime - currentTime;

            currentTime = newTime;
            accumulator = if (frameTime > 250) accumulator + 250 else accumulator + frameTime;

            while (accumulator >= deltaTime)
            {
                pumpEvents();

                flurry.update(deltaTime);

                time        = time + deltaTime;
                accumulator = accumulator - deltaTime;
            }

            flurry.tick(accumulator / deltaTime);
        }
    }

    function pumpEvents()
    {
        while (SDL.hasAnEvent())
        {
            final event = SDL.pollEvent();

            if (event.type == SDL_QUIT)
            {
                flurry.shutdown();

                Sys.exit(0);
            }
            else
            {
                dispatchEventInput(event);
                dispatchEventWindow(event);
            }
        }
    }

    function dispatchEventInput(_event : sdl.Event)
    {
        switch (_event.type)
        {
            case SDL_KEYUP:
                flurry.events.input.keyUp.onNext(new InputEventKeyState(
                    _event.key.keysym.sym,
                    _event.key.keysym.scancode,
                    _event.key.repeat,
                    toKeyMod(_event.key.keysym.mod)
                ));

            case SDL_KEYDOWN:
                flurry.events.input.keyDown.onNext(new InputEventKeyState(
                    _event.key.keysym.sym,
                    _event.key.keysym.scancode,
                    _event.key.repeat,
                    toKeyMod(_event.key.keysym.mod)
                ));

            case SDL_TEXTEDITING:
                flurry.events.input.textInput.onNext(new InputEventTextInput(
                    _event.edit.text,
                    _event.edit.start,
                    _event.edit.length,
                    Edit
                ));

            case SDL_TEXTINPUT:
                flurry.events.input.textInput.onNext(new InputEventTextInput(
                    _event.edit.text,
                    0,
                    0,
                    Edit
                ));

            case SDL_MOUSEMOTION:
                flurry.events.input.mouseMove.onNext(new InputEventMouseMove(
                    _event.motion.x,
                    _event.motion.y,
                    _event.motion.xrel,
                    _event.motion.yrel
                ));

            case SDL_MOUSEBUTTONUP:
                flurry.events.input.mouseUp.onNext(new InputEventMouseState(_event.button.x, _event.button.y,  _event.button.button));

            case SDL_MOUSEBUTTONDOWN:
                flurry.events.input.mouseDown.onNext(new InputEventMouseState(_event.button.x, _event.button.y,  _event.button.button));

            case SDL_MOUSEWHEEL:
                flurry.events.input.mouseWheel.onNext(new InputEventMouseWheel(_event.wheel.x, _event.wheel.y));

            case SDL_JOYAXISMOTION:
                //(range: -32768 to 32767)
                final gp  = gamepadInstanceSlotMapping[_event.jdevice.which];
                final val = (_event.jaxis.value + 32768) / (32767 + 32768);
                final normalized_val = (-0.5 + val) * 2.0;

                flurry.events.input.gamepadAxis.onNext(new InputEventGamepadAxis(gp.slot, _event.jaxis.axis, normalized_val));

            case SDL_JOYBUTTONUP:
                final gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                flurry.events.input.gamepadUp.onNext(new InputEventGamepadState(gp.slot, _event.jbutton.button, 0));

            case SDL_JOYBUTTONDOWN:
                final gp = gamepadInstanceSlotMapping[_event.jdevice.which];

                flurry.events.input.gamepadDown.onNext(new InputEventGamepadState(gp.slot, _event.jbutton.button, 1));

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

                final gp = gamepadInstanceSlotMapping[_event.jdevice.which];
                if (!gp.isJoystick)
                {
                    return;
                }

                gamepadInstanceSlotMapping.remove(_event.jdevice.which);
                gamepadSlots[gp.slot] = null;

                SDL.hapticRumbleStop(gp.haptic);
                SDL.hapticClose(gp.haptic);

                flurry.events.input.gamepadDevice.onNext(new InputEventGamepadDevice(
                    gp.slot,
                    SDL.gameControllerNameForIndex(_event.jdevice.which),
                    DeviceRemoved
                ));

            case SDL_CONTROLLERAXISMOTION:
                //(range: -32768 to 32767)
                final gp  = gamepadInstanceSlotMapping[_event.cdevice.which];
                final val = (_event.caxis.value + 32768) / (32767 + 32768);
                final normalized_val = (-0.5 + val) * 2.0;

                flurry.events.input.gamepadAxis.onNext(new InputEventGamepadAxis(gp.slot, _event.caxis.axis, normalized_val));

            case SDL_CONTROLLERBUTTONUP:
                final gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                flurry.events.input.gamepadUp.onNext(new InputEventGamepadState(gp.slot, _event.cbutton.button, 0));

            case SDL_CONTROLLERBUTTONDOWN:
                final gp = gamepadInstanceSlotMapping[_event.cdevice.which];

                flurry.events.input.gamepadDown.onNext(new InputEventGamepadState(gp.slot, _event.cbutton.button, 1));

            case SDL_CONTROLLERDEVICEADDED:
                setupNewGameController(_event.cdevice.which);

            case SDL_CONTROLLERDEVICEREMOVED:
                if (!gamepadInstanceSlotMapping.exists(_event.cdevice.which))
                {
                    return;
                }

                final gp = gamepadInstanceSlotMapping[_event.cdevice.which];
                gamepadInstanceSlotMapping.remove(gp.instanceID);
                gamepadSlots[gp.slot] = null;

                SDL.hapticRumbleStop(gp.haptic);
                SDL.hapticClose(gp.haptic);

                flurry.events.input.gamepadDevice.onNext(new InputEventGamepadDevice(
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
                    flurry.events.display.shown.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_HIDDEN:
                    flurry.events.display.hidden.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_EXPOSED:
                    flurry.events.display.exposed.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_MOVED:
                    flurry.events.display.moved.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_MINIMIZED:
                    flurry.events.display.minimised.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_MAXIMIZED:
                    flurry.events.display.maximised.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_RESTORED:
                    flurry.events.display.restored.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_ENTER:
                    flurry.events.display.enter.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_LEAVE:
                    flurry.events.display.leave.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_FOCUS_GAINED:
                    flurry.events.display.focusGained.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_FOCUS_LOST:
                    flurry.events.display.focusLost.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_CLOSE:
                    flurry.events.display.close.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_RESIZED:
                    flurry.events.display.resized.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    flurry.events.display.sizeChanged.onNext(new DisplayEventData(_event.window.data1, _event.window.data2));
                case _:
            }
        }
    }

    function toKeyMod(_mod : Int) : EnumFlags<KeyModifier>
    {
        final flags = new EnumFlags();

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
        final js = SDL.joystickOpen(_deviceIndex);
        if (js == null)
        {
            trace('sdl / unable to open joystick ${SDL.getError()}');
        }
        else
        {
            final jsID = SDL.joystickInstanceID(js);
            final slot = getFirstFreeGamepadSlot();

            if (slot != -1)
            {
                final haptic = SDL.hapticOpenFromJoystick(js);
                if (haptic == null)
                {
                    trace('sdl / joystick does not support haptics');
                }

                if (haptic != null && SDL.hapticRumbleInit(haptic) != 0)
                {
                    trace('sdl / could not init rumble haptics ${SDL.getError()}');
                }

                final gp = new Gamepad(true, haptic, slot, jsID);

                gamepadSlots[slot] = gp;
                gamepadInstanceSlotMapping[jsID] = gp;

                flurry.events.input.gamepadDevice.onNext(new InputEventGamepadDevice(
                    slot,
                    SDL.gameControllerNameForIndex(_deviceIndex),
                    DeviceAdded
                ));

                trace('sdl / added joystick $jsID to slot $slot');
            }
            else
            {
                trace('sdl / unable to add joystick $jsID, no more slots');
            }
        }
    }

    function setupNewGameController(_deviceIndex : Int)
    {
        final gc = SDL.gameControllerOpen(_deviceIndex);
        if (gc == null)
        {
            trace('sdl / unable to open game controller $_deviceIndex, ${SDL.getError()}');
        }
        else
        {
            final jsID = SDL.joystickInstanceID(SDL.gameControllerGetJoystick(gc));
            final slot = getFirstFreeGamepadSlot();

            if (slot != -1)
            {
                final haptic = SDL.hapticOpenFromJoystick(SDL.gameControllerGetJoystick(gc));
                if (haptic == null)
                {
                    trace('sdl / joystick does not support haptics ${SDL.getError()}');
                }

                if (haptic != null && SDL.hapticRumbleInit(haptic) != 0)
                {
                    trace('sdl / could not init rumble haptics ${SDL.getError()}');
                }

                final gp = new Gamepad(false, haptic, slot, jsID);

                gamepadSlots[slot] = gp;
                gamepadInstanceSlotMapping[jsID] = gp;

                flurry.events.input.gamepadDevice.onNext(new InputEventGamepadDevice(
                    slot,
                    SDL.gameControllerNameForIndex(_deviceIndex),
                    DeviceAdded
                ));

                trace('sdl / added game controller $jsID to slot ${gp.slot}');
            }
            else
            {
                trace('sdl / unable to add game controller $jsID, no more slots');
            }
        }
    }
    
    function onRumbleRequest(_event : InputEventGamepadRumble)
    {
        if (_event.gamepad >= gamepadSlots.length)
        {
            return;
        }

        final gp = gamepadSlots[_event.gamepad];
        if (gp.haptic != null)
        {
            if (SDL.hapticRumblePlay(gp.haptic, _event.intensity, _event.duration) != 0)
            {
                trace('sdl / unable to play rumble haptic ${SDL.getError()}');
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