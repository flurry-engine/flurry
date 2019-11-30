package tests.api.gpu.geometry;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;

using buddy.Should;

class VertexBlobTests extends BuddySuite
{
    public function new()
    {
        describe('VertexBlob', {
            it('can iterate over the vertices', {
                var count = 0;
                var blob  = new VertexBlob(3);
                for (v in blob)
                {
                    count++;
                }

                count.should.be(3);
            });

            it('can set and get data for each iterated vertex', {
                var blob  = new VertexBlob(3);

                var count = 1;
                for (v in blob)
                {
                    v.position.set(count++, count++, count++);
                    v.color.fromRGBA(count++, count++, count++, count++);
                    v.texCoord.set(count++, count++);
                }

                var count = 1;
                for (v in blob)
                {
                    v.position.x.should.be(count++);
                    v.position.y.should.be(count++);
                    v.position.z.should.be(count++);

                    v.color.r.should.be(count++);
                    v.color.g.should.be(count++);
                    v.color.b.should.be(count++);
                    v.color.a.should.be(count++);

                    v.texCoord.x.should.be(count++);
                    v.texCoord.y.should.be(count++);
                }
            });

            it('can loop over the vertex data several times with a cached iterator', {
                var blob  = new VertexBlob(3);

                var count = 1;
                for (v in blob)
                {
                    v.position.set(count++, count++, count++);
                    v.color.fromRGBA(count++, count++, count++, count++);
                    v.texCoord.set(count++, count++);
                }

                var count = 1;
                for (v in blob)
                {
                    v.position.x.should.be(count++);
                    v.position.y.should.be(count++);
                    v.position.z.should.be(count++);

                    v.color.r.should.be(count++);
                    v.color.g.should.be(count++);
                    v.color.b.should.be(count++);
                    v.color.a.should.be(count++);

                    v.texCoord.x.should.be(count++);
                    v.texCoord.y.should.be(count++);
                }

                var count = 1;
                for (v in blob)
                {
                    v.position.x.should.be(count++);
                    v.position.y.should.be(count++);
                    v.position.z.should.be(count++);

                    v.color.r.should.be(count++);
                    v.color.g.should.be(count++);
                    v.color.b.should.be(count++);
                    v.color.a.should.be(count++);

                    v.texCoord.x.should.be(count++);
                    v.texCoord.y.should.be(count++);
                }
            });
        });
    }
}