package uk.aidanlee.flurry.api.maths;

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
                    fixed(12.0        , 0).should.be(12);
                    fixed(42.424242   , 3).should.be(42.424);
                    fixed(157.35849998, 6).should.be(157.358499);
                });

                it('Can keep floats within a range', {
                    clamp( 9.4, 10, 14).should.be(10);
                    clamp(19.0, 10, 14).should.be(14);
                    clamp(-4.3, -5, 14).should.be(-4.3);
                });

                it('Can linearly interpolate a float towards a target', {
                    lerp(0, 10, 0.5).should.be(5);
                    lerp(5, 10, 0.5).should.be(7.5);
                    lerp(5, 10, 2.0).should.be(10);
                    lerp(5, 10, -1 ).should.be(5);
                });
            });
        });
    }
}
