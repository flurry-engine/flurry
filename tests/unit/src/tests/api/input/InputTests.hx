package tests.api.input;

import haxe.EnumFlags;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.input.Input;
import buddy.BuddySuite;

using buddy.Should;
using rx.Observable;

class InputTests extends BuddySuite
{
    public function new()
    {
        describe('Input', {
            it('Can track the state of keys from input events', {
                var event = new InputEvents();
                var input = new Input(event);

                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(false);
                input.wasKeyReleased(Keycodes.key_w).should.be(false);

                event.keyDown.onNext(new InputEventKeyState(Keycodes.key_w, Keycodes.toScan(Keycodes.key_w), false, new EnumFlags()));

                input.wasKeyPressed(Keycodes.key_w).should.be(true);
                input.isKeyDown(Keycodes.key_w).should.be(true);
                input.wasKeyReleased(Keycodes.key_w).should.be(false);
                input.update();

                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(true);
                input.wasKeyReleased(Keycodes.key_w).should.be(false);
                input.update();

                event.keyUp.onNext(new InputEventKeyState(Keycodes.key_w, Keycodes.toScan(Keycodes.key_w), false, new EnumFlags()));

                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(false);
                input.wasKeyReleased(Keycodes.key_w).should.be(true);
                input.update();

                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(false);
                input.wasKeyReleased(Keycodes.key_w).should.be(false);
                input.update();
            });

            it('Can will not continually reset the key state for repeat events', {
                var event = new InputEvents();
                var input = new Input(event);

                event.keyDown.onNext(new InputEventKeyState(Keycodes.key_w, Keycodes.toScan(Keycodes.key_w), false, new EnumFlags()));
                input.update();

                event.keyDown.onNext(new InputEventKeyState(Keycodes.key_w, Keycodes.toScan(Keycodes.key_w), true, new EnumFlags()));
                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(true);
                input.update();

                event.keyDown.onNext(new InputEventKeyState(Keycodes.key_w, Keycodes.toScan(Keycodes.key_w), true, new EnumFlags()));
                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(true);
                input.update();

                event.keyUp.onNext(new InputEventKeyState(Keycodes.key_w, Keycodes.toScan(Keycodes.key_w), false, new EnumFlags()));

                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(false);
                input.wasKeyReleased(Keycodes.key_w).should.be(true);
                input.update();

                input.wasKeyPressed(Keycodes.key_w).should.be(false);
                input.isKeyDown(Keycodes.key_w).should.be(false);
                input.wasKeyReleased(Keycodes.key_w).should.be(false);
                input.update();
            });

            it('Can track the state of mouse buttons from input events', {
                var event = new InputEvents();
                var input = new Input(event);

                input.wasMousePressed(1).should.be(false);
                input.isMouseDown(1).should.be(false);
                input.wasMouseReleased(1).should.be(false);

                event.mouseDown.onNext(new InputEventMouseState(0, 0, 1));

                input.wasMousePressed(1).should.be(true);
                input.isMouseDown(1).should.be(true);
                input.wasMouseReleased(1).should.be(false);
                input.update();

                input.wasMousePressed(1).should.be(false);
                input.isMouseDown(1).should.be(true);
                input.wasMouseReleased(1).should.be(false);
                input.update();

                event.mouseUp.onNext(new InputEventMouseState(0, 0, 1));

                input.wasMousePressed(1).should.be(false);
                input.isMouseDown(1).should.be(false);
                input.wasMouseReleased(1).should.be(true);
                input.update();

                input.wasMousePressed(1).should.be(false);
                input.isMouseDown(1).should.be(false);
                input.wasMouseReleased(1).should.be(false);
                input.update();
            });

            it('Can return the current normalized value of a gamepad axis', {
                var event = new InputEvents();
                var input = new Input(event);

                input.gamepadAxis(0, 0).should.be(0);
                event.gamepadAxis.onNext(new InputEventGamepadAxis(0, 0, 0.5));
                input.gamepadAxis(0, 0).should.be(0.5);
            });

            it('Can track the state of gamepad buttons from input events', {
                var event = new InputEvents();
                var input = new Input(event);

                input.wasGamepadPressed(0, 0).should.be(false);
                input.isGamepadDown(0, 0).should.be(false);
                input.wasGamepadReleased(0, 0).should.be(false);

                event.gamepadDown.onNext(new InputEventGamepadState(0, 0, 1));

                input.wasGamepadPressed(0, 0).should.be(true);
                input.isGamepadDown(0, 0).should.be(true);
                input.wasGamepadReleased(0, 0).should.be(false);
                input.update();

                input.wasGamepadPressed(0, 0).should.be(false);
                input.isGamepadDown(0, 0).should.be(true);
                input.wasGamepadReleased(0, 0).should.be(false);
                input.update();

                event.gamepadUp.onNext(new InputEventGamepadState(0, 0, 1));

                input.wasGamepadPressed(0, 0).should.be(false);
                input.isGamepadDown(0, 0).should.be(false);
                input.wasGamepadReleased(0, 0).should.be(true);
                input.update();

                input.wasGamepadPressed(0, 0).should.be(false);
                input.isGamepadDown(0, 0).should.be(false);
                input.wasGamepadReleased(0, 0).should.be(false);
                input.update();
            });

            it('Can fire an event to request a gamepad is rumbled', {
                var event = new InputEvents();
                var input = new Input(event);

                event.gamepadRumble.subscribeFunction(_data -> {
                    _data.gamepad.should.be(0);
                    _data.intensity.should.be(0.5);
                    _data.duration.should.be(2);
                });
                input.rumbleGamepad(0, 0.5, 2);
            });
        });
    }
}
