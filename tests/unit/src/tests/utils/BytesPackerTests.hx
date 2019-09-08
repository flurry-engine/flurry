package tests.utils;

import uk.aidanlee.flurry.api.resources.Resource.ShaderValue;
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
                    new ShaderValue('vec', Vector4),
                    new ShaderValue('flt', Float)
                ]).length.should.be(32);

                BytesPacker.allocateBytes(Dx11, [
                    new ShaderValue('flt', Float),
                    new ShaderValue('vec', Vector4)
                ]).length.should.be(32);

                BytesPacker.allocateBytes(Dx11, [
                    new ShaderValue('mat', Matrix4),
                    new ShaderValue('flt', Float),
                    new ShaderValue('vec', Vector4)
                ]).length.should.be(96);

                BytesPacker.allocateBytes(Dx11, [
                    new ShaderValue('flt1', Float),
                    new ShaderValue('flt2', Float),
                    new ShaderValue('flt3', Float),
                    new ShaderValue('flt4', Float)
                ]).length.should.be(16);
            });

            it('Can get the byte position to write a value into the buffer according to HLSL 16 byte alignment semantics', {
                var vals = [
                    new ShaderValue('vec', Vector4),
                    new ShaderValue('flt', Float)
                ];
                BytesPacker.getPosition(Dx11, vals, 'vec').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'flt').should.be(16);

                var vals = [
                    new ShaderValue('flt', Float),
                    new ShaderValue('vec', Vector4)
                ];
                BytesPacker.getPosition(Dx11, vals, 'flt').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'vec').should.be(16);

                var vals = [
                    new ShaderValue('mat', Matrix4),
                    new ShaderValue('flt', Float),
                    new ShaderValue('vec', Vector4)
                ];
                BytesPacker.getPosition(Dx11, vals, 'mat').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'flt').should.be(64);
                BytesPacker.getPosition(Dx11, vals, 'vec').should.be(80);

                var vals = [
                    new ShaderValue('flt1', Float),
                    new ShaderValue('flt2', Float),
                    new ShaderValue('flt3', Float),
                    new ShaderValue('flt4', Float)
                ];
                BytesPacker.getPosition(Dx11, vals, 'flt1').should.be( 0);
                BytesPacker.getPosition(Dx11, vals, 'flt2').should.be( 4);
                BytesPacker.getPosition(Dx11, vals, 'flt3').should.be( 8);
                BytesPacker.getPosition(Dx11, vals, 'flt4').should.be(12);
            });
        });
    }
}
