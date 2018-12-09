package tests.api.gpu.batcher;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class BatcherTests extends BuddySuite
{
    public function new()
    {
        describe('Batcher', {
            it('Has a unique identifier for each batcher', {
                var b1 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                var b2 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                var b3 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });

                b1.id.should.not.be(b2.id);
                b1.id.should.not.be(b3.id);

                b2.id.should.not.be(b1.id);
                b2.id.should.not.be(b3.id);

                b3.id.should.not.be(b1.id);
                b3.id.should.not.be(b2.id);
            });

            it('Has a depth which decides when the batcher contents is drawn', {
                var b1 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                var b2 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource), depth : 3.2 });

                b1.depth.should.be(0);
                b2.depth.should.be(3.2);
            });

            it('Has an array of geometry which it will batch', {
                var g = mock(Geometry);
                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });

                b.geometry.should.containExactly([]);
            });

            it('Has a camera which it will get view and projection matrices from', {
                var c = mock(Camera);
                var b = new Batcher({ camera : c, shader : mock(ShaderResource) });

                b.camera.should.be(c);
            });

            it('Has a shader which it will draw the geometry with', {
                var s = mock(ShaderResource);
                var b = new Batcher({ camera : mock(Camera), shader : s });

                b.shader.should.be(s);
            });

            it('Has a target to allow drawing to a texture', {
                var t = mock(ImageResource);

                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                b.target.should.be(null);

                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource), target : t });
                b.target.should.be(t);
            });

            it('Can be set to dirty to trigger a geometry re-ordering', {
                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                b.isDirty().should.be(false);
                b.setDirty();
                b.isDirty().should.be(true);
            });

            // The following tests really need some mocking framework.
            // Mockatoo has some functionality broken in haxe 4 preview 5
            // non extern classes can no longer implement dynamic
            // so we cannot set return values for mocked classes.

            it('Has a function to add geometry and dirty the batcher', {
                //
            });

            it('Has a function to remove geometry and dirty the batcher', {
                //
            });

            describe('Batching', {
                it('Can sort geometry to minimise the number of state changes needed to draw it', {
                    //
                });

                it('Produces geometry draw commands describing how to draw a set of geometry at once', {
                    //
                });

                it('Produces geometry draw commands which can be flagged as unchanging', {
                    //
                });

                it('Produces geometry draw commands which are either indexed or non indexed', {
                    //
                });

                it('Removes immediate geometry from itself once it has been batched', {
                    //
                });
            });
        });
    }
}
