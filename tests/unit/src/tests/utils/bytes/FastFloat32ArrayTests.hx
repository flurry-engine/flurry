package tests.utils.bytes;

import uk.aidanlee.flurry.utils.bytes.FastFloat32Array;
import buddy.BuddySuite;

using buddy.Should;

class FastFloat32ArrayTests extends BuddySuite
{
    public function new()
    {
        describe('FastFloat32Array', {
            describe('Changed Signal', {
                it('It will dispatch the changed signal when values are changed using array access', {
                    var c = 0;
                    var b = new FastFloat32Array(1);
                    b.changed.add(() -> c++);
                    b[0] = 2;
                    b[0] = 2;

                    c.should.be(1);
                });
            });
        });
    }
}