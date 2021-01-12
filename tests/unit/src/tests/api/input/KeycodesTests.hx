package tests.api.input;

import uk.aidanlee.flurry.api.input.Scancodes;
import uk.aidanlee.flurry.api.input.Keycodes;
import buddy.BuddySuite;

using buddy.Should;

class KeycodesTests extends BuddySuite
{
    public function new()
    {
        describe('Keycodes', {
            it('can a scancode to a keycode', {
                Keycodes.fromScan(Scancodes.key_w).should.be(Scancodes.key_w | Scancodes.MASK);
                Keycodes.fromScan(Scancodes.enter).should.be(Scancodes.enter | Scancodes.MASK);
            });
            describe('converting a keycode to a scancode', {
                it('can return the scancode for a keycode letter', {
                    Keycodes.toScan(Keycodes.key_w).should.be(Scancodes.key_w);
                    Keycodes.toScan(Keycodes.key_j).should.be(Scancodes.key_j);
                });
                it('can return the scancode for special keycodes', {
                    Keycodes.toScan(Keycodes.tab).should.be(Scancodes.tab);
                    Keycodes.toScan(Keycodes.enter).should.be(Scancodes.enter);
                    Keycodes.toScan(Keycodes.space).should.be(Scancodes.space);
                });
                it('will return unknown for keycodes which cant be mapped', {
                    Keycodes.toScan(Keycodes.hash).should.be(Scancodes.unknown);
                    Keycodes.toScan(Keycodes.plus).should.be(Scancodes.unknown);
                    Keycodes.toScan(Keycodes.underscore).should.be(Scancodes.unknown);
                });
            });
            describe('getting the name of a keycode', {
                it('will return the code of the letter pressed', {
                    Keycodes.name(Keycodes.key_w).should.be(Std.string(Keycodes.key_w));
                    Keycodes.name(Keycodes.key_j).should.be(Std.string(Keycodes.key_j));
                });
                it('will return keypad buttons pressed', {
                    Keycodes.name(Keycodes.kp_4).should.be('Keypad 4');
                    Keycodes.name(Keycodes.kp_multiply).should.be('Keypad *');
                });
                it('will return special keys pressed', {
                    Keycodes.name(Keycodes.enter).should.be('Enter');
                    Keycodes.name(Keycodes.space).should.be('Space');
                    Keycodes.name(Keycodes.tab).should.be('Tab');
                });
            });
        });
    }
}