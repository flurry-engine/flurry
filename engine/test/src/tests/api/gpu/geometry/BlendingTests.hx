package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.gpu.geometry.Blending;
import buddy.BuddySuite;

using buddy.Should;

class BlendingTests extends BuddySuite
{
    public function new()
    {
        describe('Blending', {
            it('Will create a blend mode to display transparent images by default', {
                var blend = new Blending();
                blend.enabled.should.be(true);
                blend.srcRGB.equals(SrcAlpha);
                blend.srcAlpha.equals(One);
                blend.dstRGB.equals(OneMinusSrcAlpha);
                blend.dstAlpha.equals(Zero);
            });

            it('Allows you to create a custom blend state through the constructor', {
                var blend = new Blending(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);
                blend.enabled.should.be(false);
                blend.srcRGB.equals(Zero);
                blend.srcAlpha.equals(OneMinusDstColor);
                blend.dstRGB.equals(One);
                blend.dstAlpha.equals(OneMinusDstAlpha);
            });

            it('Can copy another blend instances state', {
                var blend1 = new Blending();
                var blend2 = new Blending(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);

                blend1.copyFrom(blend2);
                blend1.enabled.should.be(false);
                blend1.srcRGB.equals(Zero);
                blend1.srcAlpha.equals(OneMinusDstColor);
                blend1.dstRGB.equals(One);
                blend1.dstAlpha.equals(OneMinusDstAlpha);
            });

            it('Can check if another blend instance is equal to it', {
                var blend1 = new Blending();
                var blend2 = new Blending();
                var blend3 = new Blending(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);

                blend1.equals(blend2).should.be(true);
                blend3.equals(blend2).should.be(false);
            });

            it('Can create a clone of itself', {
                var blend1 = new Blending(false, Zero, OneMinusDstColor, One, OneMinusDstAlpha);
                var blend2 = blend1.clone();

                blend1.equals(blend2).should.be(true);
                blend1.enabled = false;
                blend1.srcAlpha = OneMinusSrcColor;
                blend1.equals(blend2).should.be(false);
            });
        });
    }
}
