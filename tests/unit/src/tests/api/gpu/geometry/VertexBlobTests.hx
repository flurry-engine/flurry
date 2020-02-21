package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import buddy.BuddySuite;

using buddy.Should;

class VertexBlobTests extends BuddySuite
{
    public function new()
    {
        describe('VertexBlobBuilder', {
            it('can add a float to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat(7.1).vertexBlob();
                buffer.buffer.byteLength.should.be(4);
                buffer.floatAccess.length.should.be(1);

                buffer.floatAccess[0].should.beCloseTo(7.1);
            });
            it('can add two floats to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat2(7, 12).vertexBlob();
                buffer.buffer.byteLength.should.be(8);
                buffer.floatAccess.length.should.be(2);

                buffer.floatAccess[0].should.be(7);
                buffer.floatAccess[1].should.be(12);
            });
            it('can add three floats to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat3(7, 12, 42).vertexBlob();
                buffer.buffer.byteLength.should.be(12);
                buffer.floatAccess.length.should.be(3);

                buffer.floatAccess[0].should.be(7);
                buffer.floatAccess[1].should.be(12);
                buffer.floatAccess[2].should.be(42);
            });
            it('can add four floats to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat4(7, 12, 42, 52).vertexBlob();
                buffer.buffer.byteLength.should.be(16);
                buffer.floatAccess.length.should.be(4);

                buffer.floatAccess[0].should.be(7);
                buffer.floatAccess[1].should.be(12);
                buffer.floatAccess[2].should.be(42);
                buffer.floatAccess[3].should.be(52);
            });
            it('can copy a vector2 into the buffer', {
                final vector = new Vector2(7, 14);
                final buffer = new VertexBlobBuilder().addVector2(vector).vertexBlob();
                buffer.buffer.byteLength.should.be(8);
                buffer.floatAccess.length.should.be(2);

                buffer.floatAccess[0].should.be(7);
                buffer.floatAccess[1].should.be(14);
            });
            it('can copy a vector3 into the buffer', {
                final vector = new Vector3(7, 14, 42);
                final buffer = new VertexBlobBuilder().addVector3(vector).vertexBlob();
                buffer.buffer.byteLength.should.be(12);
                buffer.floatAccess.length.should.be(3);

                buffer.floatAccess[0].should.be(7);
                buffer.floatAccess[1].should.be(14);
                buffer.floatAccess[2].should.be(42);
            });
            it('can copy a vector4 into the buffer', {
                final vector = new Vector4(7, 14, 42, 56);
                final buffer = new VertexBlobBuilder().addVector4(vector).vertexBlob();
                buffer.buffer.byteLength.should.be(16);
                buffer.floatAccess.length.should.be(4);

                buffer.floatAccess[0].should.be(7);
                buffer.floatAccess[1].should.be(14);
                buffer.floatAccess[2].should.be(42);
                buffer.floatAccess[3].should.be(56);
            });
            it('can copy an array of floats into the buffer', {
                final array = [ 7.2, 14.6, 8.44 ];
                final buffer = new VertexBlobBuilder().addFloats(array).vertexBlob();

                buffer.buffer.byteLength.should.be(12);
                buffer.floatAccess.length.should.be(3);

                for (i in 0...array.length)
                {
                    buffer.floatAccess[i].should.beCloseTo(array[i]);
                }
            });
        });
    }
}