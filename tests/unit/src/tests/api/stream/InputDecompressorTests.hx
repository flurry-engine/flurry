package tests.api.stream;

import uk.aidanlee.flurry.api.stream.InputDecompressor;
import haxe.io.BytesInput;
import haxe.zip.Compress;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import buddy.BuddySuite;

using buddy.Should;

class InputDecompressorTests extends BuddySuite
{
    public function new()
    {
        describe('InputDecompressor Tests', {
            it('can read data from a compressed chunk', {
                final data   = 'hello compressed data!';
                final input  = new BytesInput(chunk([ data ]));
                final stream = new InputDecompressor(input, 100);

                stream.readString(data.length).should.be(data);
                stream.close();
            });
            it('can read data which spans multiple compressed chunks', {
                final data1  = 'hello compr';
                final data2  = 'essed data!';
                final input  = new BytesInput(chunk([ data1, data2 ]));
                final stream = new InputDecompressor(input, 100);

                stream.readString(data1.length + data2.length).should.be(data1 + data2);
                stream.close();
            });
        });
    }

    function chunk(_strings : Array<String>) : Bytes
    {
        final out = new BytesOutput();
        
        for (string in _strings)
        {
            final compressed = Compress.run(Bytes.ofString(string), 9);

            out.writeInt32(compressed.length);
            out.write(compressed);
        }

        return out.getBytes();
    }
}