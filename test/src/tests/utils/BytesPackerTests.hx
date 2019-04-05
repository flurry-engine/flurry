package tests.utils;

import uk.aidanlee.flurry.utils.BytesPacker;

import buddy.BuddySuite;

using buddy.Should;

class BytesPackerTests extends BuddySuite
{
    public function new()
    {
        describe('BytesPackerTests', {
            it('Can pack bytes according to HLSL 16 byte allignment semantics', {
                var b = BytesPacker.allocateBytes(Dx11, [
                    { name: 'vec', type: 'Vector4' },
                    { name: 'flt', type: 'Float' }
                ]);

                b.length.should.be(32);
            });
        });
    }
}
