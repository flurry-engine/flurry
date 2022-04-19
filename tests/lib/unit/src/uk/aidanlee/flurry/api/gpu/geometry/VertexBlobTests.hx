package uk.aidanlee.flurry.api.gpu.geometry;

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
                buffer.buffer.length.should.be(1);

                buffer.buffer[0].should.beCloseTo(7.1);
            });
            it('can add two floats to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat2(7, 12).vertexBlob();
                buffer.buffer.length.should.be(2);

                buffer.buffer[0].should.be(7);
                buffer.buffer[1].should.be(12);
            });
            it('can add three floats to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat3(7, 12, 42).vertexBlob();
                buffer.buffer.length.should.be(3);

                buffer.buffer[0].should.be(7);
                buffer.buffer[1].should.be(12);
                buffer.buffer[2].should.be(42);
            });
            it('can add four floats to the buffer', {
                final buffer = new VertexBlobBuilder().addFloat4(7, 12, 42, 52).vertexBlob();
                buffer.buffer.length.should.be(4);

                buffer.buffer[0].should.be(7);
                buffer.buffer[1].should.be(12);
                buffer.buffer[2].should.be(42);
                buffer.buffer[3].should.be(52);
            });
        });
    }
}