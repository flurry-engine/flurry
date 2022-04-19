package tests.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import buddy.BuddySuite;

using buddy.Should;

class RayTests extends BuddySuite
{
    public function new()
    {
        describe('RayTests', {
            it('contains a direction property for the ray', {
                var r = new Ray(new Vector2(2, 2), new Vector2(12, 12));
                r.dir.x.should.beCloseTo(10);
                r.dir.y.should.beCloseTo(10);
            });

            it('contains a angle property for the angle in degrees of the ray', {
                var r = new Ray(new Vector2(2, 2), new Vector2(12, 12));
                r.angle.should.be(45);
            });
        });
    }
}
