package tests.modules.differ.sat;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import uk.aidanlee.flurry.modules.differ.shapes.Polygon;
import uk.aidanlee.flurry.modules.differ.sat.SAT2D;
import uk.aidanlee.flurry.modules.differ.shapes.Circle;
import buddy.BuddySuite;

using buddy.Should;

class SAT2DTests extends BuddySuite
{
    public function new()
    {
        describe('SAT2DTests', {
            it('can test between a circle and a polygon', {
                var s1 = new Circle(16, 11, 3);
                var s2 = Polygon.rectangle(10, 10, 12, 6);

                var result = SAT2D.testCircleVsPolygon(s1, s2);

                result.shape1.should.be(s1);
                result.shape2.should.be(s2);

                result.overlap.should.be(-3);
                result.separationX.should.be(3);
                result.separationY.should.be(0);
                result.unitVectorX.should.be(1);
                result.unitVectorY.should.be(0);

                result.otherOverlap.should.be(0);
                result.otherSeparationX.should.be(0);
                result.otherSeparationY.should.be(0);
                result.otherUnitVectorX.should.be(0);
                result.otherUnitVectorY.should.be(0);

                var s1 = new Circle(14, 17, 3);
                var s2 = Polygon.rectangle(10, 10, 12, 6);

                SAT2D.testCircleVsPolygon(s1, s2).should.be(null);
            });

            it('can test between two circles', {
                var c1 = new Circle(10, 10, 3);
                var c2 = new Circle(12, 12, 4);

                var result = SAT2D.testCircleVsCircle(c1, c2);

                result.shape1.should.be(c1);
                result.shape2.should.be(c2);

                result.overlap.should.beCloseTo(4.17);
                result.separationX.should.beCloseTo(-2.95);
                result.separationY.should.beCloseTo(-2.95);
                result.unitVectorX.should.beCloseTo(-0.71);
                result.unitVectorY.should.beCloseTo(-0.71);

                result.otherOverlap.should.be(0);
                result.otherSeparationX.should.be(0);
                result.otherSeparationY.should.be(0);
                result.otherUnitVectorX.should.be(0);
                result.otherUnitVectorY.should.be(0);

                var c1 = new Circle(10, 10, 3);
                var c2 = new Circle(16, 16, 2);
                SAT2D.testCircleVsCircle(c1, c2).should.be(null);
            });

            it('can test bewtween two polygons', {
                var p1 = Polygon.square(10, 10, 5);
                var p2 = Polygon.create(12, 14, 8, 7);

                var result = SAT2D.testPolygonVsPolygon(p1, p2);

                result.shape1.should.be(p1);
                result.shape2.should.be(p2);

                result.overlap.should.beCloseTo(4.97);
                result.separationX.should.be(0);
                result.separationY.should.beCloseTo(-4.97);
                result.unitVectorX.should.be( 0);
                result.unitVectorY.should.be(-1);

                result.otherOverlap.should.beCloseTo(-4.97);
                result.otherSeparationX.should.be(0);
                result.otherSeparationY.should.beCloseTo(-4.97);
                result.otherUnitVectorX.should.be( 0);
                result.otherUnitVectorY.should.be(-1);
            });

            it('can test between a ray and a circle', {
                var r = new Ray(new Vector(2, 2), new Vector(12, 12));
                var c = new Circle(7, 7, 3);

                var result = SAT2D.testRayVsCircle(r, c);

                result.shape.should.be(c);
                result.ray.should.be(r);
                result.start.should.beCloseTo(0.29);
                result.end.should.beCloseTo(0.71);
            });

            it('can test between a ray and a polygon', {
                var r = new Ray(new Vector(2, 2), new Vector(12, 12));
                var p = Polygon.square(7, 7, 3);

                var result = SAT2D.testRayVsPolygon(r, p);

                result.shape.should.be(p);
                result.ray.should.be(r);
                result.start.should.beCloseTo(0.35);
                result.end.should.beCloseTo(0.65);
            });

            it('can test between two rays', {
                var r1 = new Ray(new Vector(2, 2), new Vector(12, 12));
                var r2 = new Ray(new Vector(12, 2), new Vector(2, 12));

                var result = SAT2D.testRayVsRay(r1, r2);

                result.ray1.should.be(r1);
                result.ray2.should.be(r2);
                result.u1.should.beCloseTo(0.5);
                result.u2.should.beCloseTo(0.5);
            });
        });
    }
}
