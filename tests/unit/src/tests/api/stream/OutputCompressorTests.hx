package tests.api.stream;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.zip.Compress;
import buddy.BuddySuite;
import uk.aidanlee.flurry.api.stream.OutputCompressor;

using buddy.Should;

class OutputCompressorTests extends BuddySuite
{
    public function new()
    {
        describe('OutputCompressor Tests', {
            describe('Data written to the stream is compressed into a length prefixed chunk', {
                final data   = 'hello compressed stream!';
                final level  = 9;
                final chunks = 32;
                final output = new BytesOutput();
                final stream = new OutputCompressor(output, level, chunks);

                stream.writeString(data);
                stream.close();

                final expected = Compress.run(Bytes.ofString(data), level);
                final actual   = output.getBytes();

                it('will prefix the chunk with a 32bit int length', {
                    actual.getInt32(0).should.be(expected.length);
                });
                it('will then contain the DEFLATE compressed data', {
                    actual.sub(4, actual.length - 4).compare(expected).should.be(0);
                });
            });

            describe('Multiple chunks will be written if the input data exceeds the chunk size', {
                final data1  = 'hello compressed stream!';
                final data2  = 'even more data to pack';
                final level  = 9;
                final chunks = 32;
                final output = new BytesOutput();
                final stream = new OutputCompressor(output, level, chunks);

                stream.writeString(data1);
                stream.writeString(data2);
                stream.close();

                final expected1 = Compress.run(Bytes.ofString('hello compressed stream!even mor'), level);
                final expected2 = Compress.run(Bytes.ofString('e data to pack'), level);
                final actual    = output.getBytes();

                it('will prefix the first chunk with a 32bit int length', {
                    actual.getInt32(0).should.be(expected1.length);
                });
                it('will then contain the first chunks DEFLATE compressed data', {
                    final length = actual.getInt32(0);
                    actual.sub(4, length).compare(expected1).should.be(0);
                });
                it('will prefix the second chunk with a 32bit int length', {
                    final offset = actual.getInt32(0) + 4;
                    actual.getInt32(offset).should.be(expected2.length);
                });
                it('will then contain the second chunks DEFLATE compressed data', {
                    final offset = actual.getInt32(0) + 4;
                    final length = actual.getInt32(offset);
                    actual.sub(offset + 4, length).compare(expected2).should.be(0);
                });
            });

            describe('Manually calling flush will write a chunk regardless of the chunk size', {
                final data1  = 'hello ';
                final data2  = 'compressed stream!';
                final level  = 9;
                final chunks = 32;
                final output = new BytesOutput();
                final stream = new OutputCompressor(output, level, chunks);

                stream.writeString(data1);
                stream.flush();
                stream.writeString(data2);
                stream.close();

                final expected1 = Compress.run(Bytes.ofString('hello '), level);
                final expected2 = Compress.run(Bytes.ofString('compressed stream!'), level);
                final actual    = output.getBytes();

                it('will prefix the first chunk with a 32bit int length', {
                    actual.getInt32(0).should.be(expected1.length);
                });
                it('will then contain the first chunks DEFLATE compressed data', {
                    final length = actual.getInt32(0);
                    actual.sub(4, length).compare(expected1).should.be(0);
                });
                it('will prefix the second chunk with a 32bit int length', {
                    final offset = actual.getInt32(0) + 4;
                    actual.getInt32(offset).should.be(expected2.length);
                });
                it('will then contain the second chunks DEFLATE compressed data', {
                    final offset = actual.getInt32(0) + 4;
                    final length = actual.getInt32(offset);
                    actual.sub(offset + 4, length).compare(expected2).should.be(0);
                });
            });
        });
    }
}