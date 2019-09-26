package tests.api.maths;

import uk.aidanlee.flurry.api.maths.Transformation;
import buddy.BuddySuite;

using buddy.Should;

class TransformationTests extends BuddySuite
{
    public function new()
    {
        describe('Transformation', {
            it('will update the local space position when setting the position', {
                var t = new Transformation();
                t.position.set_xyz(2, 4, 6);
                t.position.x.should.be(t.local.position.x);
                t.position.y.should.be(t.local.position.y);
                t.position.z.should.be(t.local.position.z);
            });

            it('will update the local space scale when setting the position', {
                var t = new Transformation();
                t.scale.set_xyz(2, 4, 6);
                t.scale.x.should.be(t.local.scale.x);
                t.scale.y.should.be(t.local.scale.y);
                t.scale.z.should.be(t.local.scale.z);
            });

            it('will update the local space rotation when setting the position', {
                var t = new Transformation();
                t.rotation.set_xyz(2, 4, 6);
                t.rotation.x.should.be(t.local.rotation.x);
                t.rotation.y.should.be(t.local.rotation.y);
                t.rotation.z.should.be(t.local.rotation.z);
            });

            it('will multiply by its parents world transformation', {
                var p = new Transformation();
                p.position.set_xy(16, 16);

                var c = new Transformation();
                c.position.set_xy(8, 8);

                c.parent = p;
                c.world.position.x.should.be(24);
                c.world.position.y.should.be(24);
            });

            it('will recalculate the world transformation when the parent transformation has changed', {
                var p = new Transformation();
                var c = new Transformation();

                c.parent = p;
                c.position.set_xy(8, 8);

                c.world.position.x.should.be(8);
                c.world.position.y.should.be(8);

                p.position.set_xy(16, 16);
                c.world.position.x.should.be(24);
                c.world.position.y.should.be(24);
            });
        });
    }
}