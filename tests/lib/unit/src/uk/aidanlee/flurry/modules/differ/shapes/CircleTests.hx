package tests.modules.differ.shapes;

import uk.aidanlee.flurry.modules.differ.shapes.Circle;
import buddy.BuddySuite;

using buddy.Should;

class CircleTests extends BuddySuite
{
    public function new()
    {
        describe('CircleTests', {
            it('can access the original radius', {
                var r = 6;
                var c = new Circle(10, 12, r);
                c.radius.should.be(r);
            });

            it('can access the radius scaled by the x scale', {
                var r = 6;
                var s = 2.4;
                var c = new Circle(10, 12, r);
                c.scaleX = s;

                c.transformedRadius.should.beCloseTo(r * s);
            });
        });
    }
}
