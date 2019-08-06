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
                BytesPacker.allocateBytes(Dx11, [
                    { name: 'vec', type: 'Vector4' },
                    { name: 'flt', type: 'Float' }
                ]).length.should.be(32);

                BytesPacker.allocateBytes(Dx11, [
                    { name: 'flt', type: 'Float' },
                    { name: 'vec', type: 'Vector4' }
                ]).length.should.be(32);

                BytesPacker.allocateBytes(Dx11, [
                    { name: 'mat', type: 'Matrix4' },
                    { name: 'flt', type: 'Float' },
                    { name: 'vec', type: 'Vector4' }
                ]).length.should.be(96);

                BytesPacker.allocateBytes(Dx11, [
                    { name: 'flt1', type: 'Float' },
                    { name: 'flt2', type: 'Float' },
                    { name: 'flt3', type: 'Float' },
                    { name: 'flt4', type: 'Float' }
                ]).length.should.be(16);
            });

            it('Can get the byte position to write a value into the buffer according to HLSL 16 byte alignment semantics', {
                var vals = [
                    { name: 'vec', type: 'Vector4' },
                    { name: 'flt', type: 'Float' }
                ];
                BytesPacker.getPosition(Dx11, vals, 'vec').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'flt').should.be(16);

                var vals = [
                    { name: 'flt', type: 'Float' },
                    { name: 'vec', type: 'Vector4' }
                ];
                BytesPacker.getPosition(Dx11, vals, 'flt').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'vec').should.be(16);

                var vals = [
                    { name: 'mat', type: 'Matrix4' },
                    { name: 'flt', type: 'Float' },
                    { name: 'vec', type: 'Vector4' }
                ];
                BytesPacker.getPosition(Dx11, vals, 'mat').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'flt').should.be(64);
                BytesPacker.getPosition(Dx11, vals, 'vec').should.be(80);

                var vals = [
                    { name: 'flt1', type: 'Float' },
                    { name: 'flt2', type: 'Float' },
                    { name: 'flt3', type: 'Float' },
                    { name: 'flt4', type: 'Float' }
                ];
                BytesPacker.getPosition(Dx11, vals, 'flt1').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'flt2').should.be( 4);
                BytesPacker.getPosition(Dx11, vals, 'flt3').should.be( 8);
                BytesPacker.getPosition(Dx11, vals, 'flt4').should.be(12);
            });
        });
    }
}
