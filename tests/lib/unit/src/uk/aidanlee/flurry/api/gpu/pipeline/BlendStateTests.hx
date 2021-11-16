package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.gpu.pipeline.BlendOp;
import uk.aidanlee.flurry.api.gpu.pipeline.BlendMode;
import buddy.BuddySuite;

using buddy.Should;

class BlendStateTests extends BuddySuite
{
    public function new()
    {
        describe('Blending', {
            it('Will create a blend mode to display transparent images by default', {
                final blend = BlendState.none;
                blend.enabled.should.be(true);
                blend.srcFactor.should.be(One);
                blend.dstFactor.should.be(OneMinusSrcAlpha);
                blend.op.should.be(Add);
            });

            it('Allows you to create a custom blend state through the constructor', {
                final blend = new BlendState(false, Zero, OneMinusDstColour, Add);
                blend.enabled.should.be(false);
                blend.srcFactor.should.be(Zero);
                blend.dstFactor.should.be(OneMinusDstColour);
                blend.op.should.be(Add);
            });

            it('Can check if another blend instance is equal to it', {
                final blend1 = BlendState.none;
                final blend2 = BlendState.none;
                final blend3 = new BlendState(false, Zero, OneMinusDstColour, Subtract);

                (blend1 == blend2).should.be(true);
                (blend1 == blend3).should.be(false);
                (blend3 == blend2).should.be(false);
            });
        });
    }
}
