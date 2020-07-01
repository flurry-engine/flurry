package tests.api.stream;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.Compress;
import hxbit.Serializer;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.resources.Resource.TextResource;
import uk.aidanlee.flurry.api.stream.ParcelOutput;
import buddy.BuddySuite;

using buddy.Should;

class ParcelOutputTests extends BuddySuite
{
    public function new()
    {
        describe('ParcelOutput tests', {
            describe('Creating parcels with no compression', {
                final output = new BytesOutput();
                final parcel = new ParcelOutput(output, None);
                final asset  = new TextResource('text_id', 'hello world!');

                parcel.add(SerialisedResource(asset));
                parcel.commit();
                parcel.close();

                final actual   = output.getBytes();
                final expected = serialise(asset);

                it('will write the "PRCL" magic bytes at the beginning of the header', {
                    actual.getString(0, 4).should.be('PRCL');
                });

                it('will write a byte indicating no compression is applied to the parcel data', {
                    actual.get(4).should.be(0);
                });

                it('will write an integer indicating how many payload items are in the parcel', {
                    actual.getInt32(5).should.be(1);
                });

                it('will write a byte indicating a serialised asset is the next item', {
                    actual.get(9).should.be(0);
                });

                it('will write an integer representing the length of the serialised assets bytes', {
                    actual.getInt32(10).should.be(expected.length);
                });

                it('will write the serialised assets bytes', {
                    final length = actual.getInt32(10);
                    actual.sub(14, length).compare(expected).should.be(0);
                });
            });
            describe('Creating parcels with DEFLATE compression', {
                final level  = 4;
                final chunks = 10000000;
                final output = new BytesOutput();
                final parcel = new ParcelOutput(output, Deflate(4, chunks));
                final asset  = new TextResource('text_id', 'hello world!');

                parcel.add(SerialisedResource(asset));
                parcel.commit();
                parcel.close();

                final actual     = output.getBytes();
                final tempOutput = new BytesOutput();
                final serialised = serialise(asset);
                tempOutput.writeByte(0);
                tempOutput.writeInt32(serialised.length);
                tempOutput.write(serialised);
                final expected = Compress.run(tempOutput.getBytes(), level);

                it('will write the "PRCL" magic bytes at the beginning of the data', {
                    actual.getString(0, 4).should.be('PRCL');
                });

                it('will write a byte indicating compression is applied to the parcel data', {
                    actual.get(4).should.be(1);
                });

                it('will write a byte indicating the DEFLATE compression level', {
                    actual.get(5).should.be(level);
                });

                it('will write an int indicating the chunk size used', {
                    actual.getInt32(6).should.be(chunks);
                });

                it('will write an integer indicating how many payload items are in the parcel', {
                    actual.getInt32(10).should.be(1);
                });

                it('will write the serialised chunk', {
                    final length = actual.getInt32(14);
                    actual.sub(18, length).compare(expected).should.be(0);
                });
            });
        });
    }

    function serialise(_asset : Resource) : Bytes
    {
        return new Serializer().serialize(_asset);
    }
}