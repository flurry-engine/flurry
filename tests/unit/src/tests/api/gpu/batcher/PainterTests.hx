package tests.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.batcher.Painter;
import buddy.BuddySuite;

using buddy.Should;
using mockatoo.Mockatoo;

class PainterTests extends BuddySuite
{
    public function new()
    {
        describe('Painter', {
            describe('Implementing IBatchable', {
                final camera  = new Camera2D(1280, 720, TopLeft, ZeroToNegativeOne);
                final painter = new Painter({
                    camera : camera,
                    depth  : 4.2,
                    target : Texture(7),
                    shader : 3,
                    stencilOptions : StencilState.none,
                    depthOptions   : DepthState.none
                });

                it('can fetch the depth of the painter', {
                    painter.getDepth().should.be(4.2);
                });
                it('can fetch the target of the painter', {
                    switch painter.getTarget()
                    {
                        case Backbuffer: fail('expected texture target');
                        case Texture(_image): _image.should.be(7);
                    }
                });
                it('will fetch the last (default) shader in the stack', {
                    painter.getShader().should.be(3);
                });
            });
        });
    }
}