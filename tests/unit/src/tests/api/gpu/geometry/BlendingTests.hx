package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.gpu.BlendMode;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import buddy.BuddySuite;

using buddy.Should;

class BlendingTests extends BuddySuite
{
    public function new()
    {
        describe('Blending', {
            it('Will create a blend mode to display transparent images by default', {
                final blend = new BlendState();
                blend.enabled.should.be(true);
                blend.srcRGB.should.be(SrcAlpha);
                blend.srcAlpha.should.be(One);
                blend.dstRGB.should.be(OneMinusSrcAlpha);
                blend.dstAlpha.should.be(Zero);
            });

            it('Allows you to create a custom blend state through the constructor', {
                final blend = new BlendState(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);
                blend.enabled.should.be(false);
                blend.srcRGB.should.be(Zero);
                blend.srcAlpha.should.be(OneMinusDstColor);
                blend.dstRGB.should.be(One);
                blend.dstAlpha.should.be(OneMinusDstAlpha);
            });

            it('Can copy another blend instances state', {
                final blend1 = new BlendState();
                final blend2 = new BlendState(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);

                blend1.copyFrom(blend2);
                blend1.enabled.should.be(false);
                blend1.srcRGB.should.be(Zero);
                blend1.srcAlpha.should.be(OneMinusDstColor);
                blend1.dstRGB.should.be(One);
                blend1.dstAlpha.should.be(OneMinusDstAlpha);
            });

            it('Can check if another blend instance is equal to it', {
                final blend1 = new BlendState();
                final blend2 = new BlendState();
                final blend3 = new BlendState(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);

                blend1.equals(blend2).should.be(true);
                blend3.equals(blend2).should.be(false);
            });

            it('Can create a clone of itself', {
                final blend1 = new BlendState(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);
                final blend2 = blend1.clone();

                blend1.equals(blend2).should.be(true);
                blend1.enabled = false;
                blend1.srcAlpha = OneMinusSrcColor;
                blend1.equals(blend2).should.be(false);
            });
        });
    }
}
