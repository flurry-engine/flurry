package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob.IndexBlobBuilder;
import buddy.BuddySuite;

using buddy.Should;

class IndexBlobTests extends BuddySuite
{
    public function new()
    {
        describe('IndexBlobBuilder', {
            it('can add an array of ints as ushorts to the buffer', {
                final ints = [ 5, 6, 7, 8, 9, 10 ];
                final blob = new IndexBlobBuilder().addInts([ 5, 6, 7, 8, 9, 10 ]).indexBlob();

                blob.buffer.length.should.be(ints.length);

                for (i in 0...ints.length)
                {
                    blob.buffer[i].should.be(ints[i]);
                }
            });
            it('can add an integer as a ushort to the buffer', {
                final blob = new IndexBlobBuilder().addInt(7).indexBlob();

                blob.buffer.length.should.be(1);

                blob.buffer[0].should.be(7);
            });
        });
    }
}