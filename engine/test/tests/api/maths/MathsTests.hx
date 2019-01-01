package tests.api.maths;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.maths.Maths;

using buddy.Should;

class MathsTests extends BuddySuite
{
    public function new()
    {
        describe('Maths', {
            describe('Utils', {
                it('Can fix a float to a specified number of significant figures', {
                    Maths.fixed(12.0        , 0).should.be(12);
                    Maths.fixed(42.424242   , 3).should.be(42.424);
                    Maths.fixed(157.35849998, 6).should.be(157.358499);
                });

                it('Can keep floats within a range', {
                    Maths.clamp( 9.4, 10, 14).should.be(10);
                    Maths.clamp(19.0, 10, 14).should.be(14);
                    Maths.clamp(-4.3, -5, 14).should.be(-4.3);
                });

                it('Can linearly interpolate a float towards a target', {
                    Maths.lerp(0, 10, 0.5).should.be(5);
                    Maths.lerp(5, 10, 0.5).should.be(7.5);
                    Maths.lerp(5, 10, 2.0).should.be(10);
                    Maths.lerp(5, 10, -1 ).should.be(5);
                });

                it('Can convert radians to degrees', {
                    Maths.toDegrees(0.5).should.be(0.5 * 180 / Math.PI);
                });

                it('Can convert degrees to radians', {
                    Maths.toRadians(180).should.be(180 * Math.PI / 180);
                });

                it('Can calculate the x position for an angle in degrees and direction', {
                    Maths.lengthdir_x(20, 45).should.beCloseTo(Math.cos(45 * Math.PI / 180) * 20);
                });

                it('Can calculate the y position for an angle in degrees and direction', {
                    Maths.lengthdir_x(20, 45).should.beCloseTo(Math.sin(45 * Math.PI / 180) * 20);
                });
            });
        });
    }
}
