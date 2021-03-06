package tests.api.buffers;

import hxrx.observer.Observer;
import haxe.io.Bytes;
import uk.aidanlee.flurry.api.buffers.BufferData;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;
import buddy.BuddySuite;

using buddy.Should;

class UInt16BufferDataTests extends BuddySuite
{
    public function new()
    {
        describe('UInt16BufferData', {
            it('can allocate a float32 buffer of a specified size', {
                final size   = 4;
                final buffer = new UInt16BufferData(size);
                buffer.length.should.be(size);
            });

            it('can set the float elements of the buffer', {
                final size   = 4;
                final buffer = new UInt16BufferData(size);
                
                for (i in 0...buffer.length)
                {
                    buffer.set(i, i);
                }

                for (i in 0...buffer.length)
                {
                    buffer.get(i).should.be(i);
                }
            });

            it('will fire a changed signal when data is modified', {
                var count  = 0;
                final size   = 4;
                final buffer = new UInt16BufferData(size);
                buffer.subscribe(new Observer(_ -> count++, null, null));

                for (i in 0...buffer.length)
                {
                    buffer.set(i, 0);
                }

                count.should.be(size);
            });

            it('it will return the correct length and offset in bytes and floats', {
                // initial sizes check
                final buffer = new UInt16BufferData(8);
                buffer.length.should.be(8);
                buffer.offset.should.be(0);

                // update float offset and sizes, make sure byte versions match.
                buffer.offset = 2;
                buffer.length = 4;
                
                buffer.offset.should.be(2);
                buffer.length.should.be(4);
            });

            it('it will correctly set the bytes in the buffers range', {
                // zero the bytes
                final bytes  = new BufferData(Bytes.alloc(16), 0, 0);
                for (i in 0...bytes.bytes.length)
                {
                    bytes.bytes.set(0, 0);
                }

                // set our float buffer to cover the middle four floats
                final buffer : UInt16BufferData = bytes;
                buffer.offset = 2;
                buffer.length = 4;
                
                for (i in 0...buffer.length)
                {
                    buffer.set(i, i + 1);
                }

                // check all underlying bytes
                bytes.bytes.getUInt16( 0).should.be(0);
                bytes.bytes.getUInt16( 2).should.be(0);
                bytes.bytes.getUInt16( 4).should.be(1);
                bytes.bytes.getUInt16( 6).should.be(2);
                bytes.bytes.getUInt16( 8).should.be(3);
                bytes.bytes.getUInt16(10).should.be(4);
                bytes.bytes.getUInt16(12).should.be(0);
                bytes.bytes.getUInt16(14).should.be(0);
            });
        });
    }
}