package uk.aidanlee.flurry.api.gpu.pipeline;

import uk.aidanlee.flurry.api.gpu.pipeline.StencilFunction;
import uk.aidanlee.flurry.api.gpu.pipeline.ComparisonFunction;
import buddy.BuddySuite;

using buddy.Should;

class StencilStateTests extends BuddySuite
{
    public function new()
    {
        describe('StencilTests', {
            it('Will create a disabled stencil state by default', {
                final stencil = StencilState.none;
                stencil.enabled.should.be(false);
                stencil.frontFunc.should.be(Always);
                stencil.frontTestFail.should.be(Keep);
                stencil.frontDepthTestFail.should.be(Keep);
                stencil.frontDepthTestPass.should.be(Keep);
                stencil.backFunc.should.be(Always);
                stencil.backTestFail.should.be(Keep);
                stencil.backDepthTestFail.should.be(Keep);
                stencil.backDepthTestPass.should.be(Keep);
            });

            it('Allows you to create a custom stencil state through the constructor', {
                final stencil = new StencilState(true, Equal, Zero, Replace, Invert, GreaterThan, Increment, IncrementWrap, Decrement);
                stencil.enabled.should.be(true);
                stencil.frontFunc.should.be(Equal);
                stencil.frontTestFail.should.be(Zero);
                stencil.frontDepthTestFail.should.be(Replace);
                stencil.frontDepthTestPass.should.be(Invert);
                stencil.backFunc.should.be(GreaterThan);
                stencil.backTestFail.should.be(Increment);
                stencil.backDepthTestFail.should.be(IncrementWrap);
                stencil.backDepthTestPass.should.be(Decrement);
            });

            it('Can check if another blend instance is equal to it', {
                final stencil1 = StencilState.none;
                final stencil2 = StencilState.none;
                final stencil3 = new StencilState(true, Equal, Zero, Replace, Invert, GreaterThan, Increment, IncrementWrap, Decrement);

                (stencil1 == stencil2).should.be(true);
                (stencil1 == stencil3).should.be(false);
                (stencil2 == stencil3).should.be(false);
            });
        });
    }
}
