package tests.api.input;

import uk.aidanlee.flurry.api.input.Scancodes;
import buddy.BuddySuite;

using buddy.Should;

class ScancodesTests extends BuddySuite
{
    public function new()
    {
        describe('Keycodes', {
            describe('getting the name of a scancode', {
                it('can get the letter pressed', {
                    Scancodes.name(Scancodes.key_w).should.be('W');
                    Scancodes.name(Scancodes.key_j).should.be('J');
                });
                it('can get the name of special keys', {
                    Scancodes.name(Scancodes.enter).should.be('Enter');
                    Scancodes.name(Scancodes.space).should.be('Space');
                    Scancodes.name(Scancodes.tab).should.be('Tab');
                });
                it('will return an empty string if it is an unknown keycode', {
                    Scancodes.name(-1).should.be('');
                    Scancodes.name(10000).should.be('');
                });
            });
        });
    }
}