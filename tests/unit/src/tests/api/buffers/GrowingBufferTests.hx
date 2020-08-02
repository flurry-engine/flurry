package tests.api.buffers;

import uk.aidanlee.flurry.api.buffers.GrowingBuffer;
import buddy.BuddySuite;

using rx.Observable;
using buddy.Should;

class GrowingBufferTests extends BuddySuite
{
    public function new()
    {
        describe('GrowingBuffer', {
            final buffer = new GrowingBuffer();

            describe('adding a float', {
                final val = 7;

                buffer.reset();
                buffer.addFloat(val);

                final bytes = buffer.getBytes();

                it('should contain 4 bytes', {
                    bytes.length.should.be(4);
                });
                it('should contain just the float added', {
                    bytes.getFloat(0).should.be(val);
                });
            });
            describe('adding two floats', {
                final val1 = 8;
                final val2 = 24;

                buffer.reset();
                buffer.addFloat2(val1, val2);

                final bytes = buffer.getBytes();

                it('should contain 8 bytes', {
                    bytes.length.should.be(8);
                });
                it('should contain just the two floats added', {
                    bytes.getFloat(0).should.be(val1);
                    bytes.getFloat(4).should.be(val2);
                });
            });
            describe('adding three floats', {
                final val1 = 254;
                final val2 = 464;
                final val3 = 42;

                buffer.reset();
                buffer.addFloat3(val1, val2, val3);

                final bytes = buffer.getBytes();

                it('should contain 12 bytes', {
                    bytes.length.should.be(12);
                });
                it('should contain the three floats added', {
                    bytes.getFloat(0).should.be(val1);
                    bytes.getFloat(4).should.be(val2);
                    bytes.getFloat(8).should.be(val3);
                });
            });
            describe('adding four floats', {
                final val1 = 923;
                final val2 = 12;
                final val3 = 642;
                final val4 = 85;

                buffer.reset();
                buffer.addFloat4(val1, val2, val3, val4);

                final bytes = buffer.getBytes();

                it('should contain 16 bytes', {
                    bytes.length.should.be(16);
                });
                it('should contain the four floats added', {
                    bytes.getFloat( 0).should.be(val1);
                    bytes.getFloat( 4).should.be(val2);
                    bytes.getFloat( 8).should.be(val3);
                    bytes.getFloat(12).should.be(val4);
                });
            });
            describe('adding a uint16', {
                final val = 7;
                
                buffer.reset();
                buffer.addUInt16(val);

                final bytes = buffer.getBytes();

                it('should contain 2 bytes', {
                    bytes.length.should.be(2);
                });
                it('should contain just the int added', {
                    bytes.getUInt16(0).should.be(val);
                });
            });
            describe('adding an array of uint16s', {
                final vals = [ 34, 765, 5, 895 ];

                buffer.reset();
                buffer.addUInt16s(vals);

                final bytes = buffer.getBytes();

                it('should contain 8 bytes', {
                    bytes.length.should.be(8);
                });
                it('should contain the array of ints added', {
                    for (i in 0...vals.length)
                    {
                        bytes.getUInt16(i * 2).should.be(vals[i]);
                    }
                });
            });
        });
    }
}