package tests.api.maths;

import buddy.BuddySuite;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Circle;

using buddy.Should;

class CircleTests extends BuddySuite
{
    public function new()
    {
        describe('Circle', {
            describe('General', {
                it('Can set the position and radius', {
                    var x = 12;
                    var y = 4;
                    var r = 3;

                    var c = new Circle();
                    c.set(x, y, r);

                    c.x.should.be(x);
                    c.y.should.be(y);
                    c.r.should.be(r);
                });
                it('Can copy the position and radius from another circle', {
                    var x = 12;
                    var y = 4;
                    var r = 3;

                    var c1 = new Circle(x, y, r);
                    var c2 = new Circle();
                    c2.copyFrom(c1);

                    c2.x.should.be(c1.x);
                    c2.y.should.be(c1.y);
                    c2.r.should.be(c1.r);
                });
                it('Can clone itself', {
                    var x = 12;
                    var y = 4;
                    var r = 3;

                    var c1 = new Circle(x, y, r);
                    var c2 = c1.clone();

                    c2.x.should.be(c1.x);
                    c2.y.should.be(c1.y);
                    c2.r.should.be(c1.r);
                });
            });

            describe('Maths', {
                it('Can check if a vector is within the circle', {
                    var x = 12;
                    var y = 4;
                    var r = 3;
                    var c = new Circle(x, y, r);

                    var v1x = 2;
                    var v1y = 2;
                    var v1 = new Vector(v1x, v1y);

                    var v2x = x + (r / 2);
                    var v2y = y + (r / 2);
                    var v2 = new Vector(v2x, v2y);

                    c.containsPoint(v1).should.not.be(true);
                    c.containsPoint(v2).should.be(true);
                });
            });
        });
    }
}
