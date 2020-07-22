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
                final blend = BlendState.none;
                blend.enabled.should.be(true);
                blend.srcRgb.should.be(SrcAlpha);
                blend.srcAlpha.should.be(One);
                blend.dstRgb.should.be(OneMinusSrcAlpha);
                blend.dstAlpha.should.be(Zero);
            });

            it('Allows you to create a custom blend state through the constructor', {
                final blend = new BlendState(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);
                blend.enabled.should.be(false);
                blend.srcRgb.should.be(Zero);
                blend.srcAlpha.should.be(OneMinusDstColor);
                blend.dstRgb.should.be(One);
                blend.dstAlpha.should.be(OneMinusDstAlpha);
            });

            it('Can check if another blend instance is equal to it', {
                final blend1 = BlendState.none;
                final blend2 = BlendState.none;
                final blend3 = new BlendState(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);

                (blend1 == blend2).should.be(true);
                (blend3 == blend2).should.be(false);
            });
        });
    }
}
