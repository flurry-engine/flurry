package tests.api.gpu.textures;

import uk.aidanlee.flurry.api.gpu.textures.EdgeClamping;
import uk.aidanlee.flurry.api.gpu.textures.Filtering;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import buddy.BuddySuite;

using buddy.Should;

class SamplerStateTests extends BuddySuite
{
    public function new()
    {
        describe('SamplerState', {
            it('can create a default nearest neighbour clamp sampler', {
                final sampler = SamplerState.nearest;
                sampler.uClamping.should.be(Clamp);
                sampler.vClamping.should.be(Clamp);
                sampler.minification.should.be(Nearest);
                sampler.magnification.should.be(Nearest);
            });
            it('can create a default linear neighbour clamp sampler', {
                final sampler = SamplerState.linear;
                sampler.uClamping.should.be(Clamp);
                sampler.vClamping.should.be(Clamp);
                sampler.minification.should.be(Linear);
                sampler.magnification.should.be(Linear);
            });
            it('allows you to create a custom sampler through the constructor', {
                final sampler = new SamplerState(Border, Mirror, Nearest, Linear);
                sampler.uClamping.should.be(Border);
                sampler.vClamping.should.be(Mirror);
                sampler.minification.should.be(Nearest);
                sampler.magnification.should.be(Linear);
            });
            it('can check if samplers are equal to each other', {
                final sampler1 = SamplerState.linear;
                final sampler2 = SamplerState.linear;
                final sampler3 = SamplerState.nearest;
                final sampler4 = new SamplerState(Border, Mirror, Nearest, Linear);

                (sampler1 == sampler2).should.be(true);
                (sampler1 == sampler3).should.be(false);
                (sampler1 == sampler4).should.be(false);
                (sampler2 == sampler3).should.be(false);
                (sampler2 == sampler4).should.be(false);
                (sampler3 == sampler4).should.be(false);
            });
        });
    }
}