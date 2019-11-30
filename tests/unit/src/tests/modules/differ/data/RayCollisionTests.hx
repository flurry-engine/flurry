package tests.modules.differ.data;

import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import uk.aidanlee.flurry.modules.differ.shapes.Shape;
import uk.aidanlee.flurry.modules.differ.data.RayCollision;
import uk.aidanlee.flurry.api.maths.Vector2;
import buddy.BuddySuite;
import mockatoo.Mockatoo.mock;

using buddy.Should;

class RayCollisionTests extends BuddySuite
{
    public function new()
    {
        describe('RayCollisionTests', {
            it('can copy its values from another ray collision', {
                var r1 = new RayCollision(null, null, 2, 7);
                var r2 = new RayCollision(null, null, 3, 8);

                r1.start.should.not.be(r2.start);
                r1.end.should.not.be(r2.end);

                r2.copyFrom(r1);

                r1.start.should.be(r2.start);
                r1.end.should.be(r2.end);
            });

            it('can create a recursive clone of itself', {
                var r1 = new RayCollision(null, null, 2, 7);
                var r2 = r1.clone();
                r2.shape.should.be(r1.shape);
                r2.ray.should.be(r1.ray);
                r2.start.should.be(r1.start);
                r2.end.should.be(r1.end);

                r2.set(r1.shape, r1.ray, 3, 8);
                r2.shape.should.be(r1.shape);
                r2.ray.should.be(r1.ray);
                r2.start.should.not.be(r1.start);
                r2.end.should.not.be(r1.end);
            });

            it('can update its values allowing re-use', {
                var result = new RayCollision(null, null, 2, 6);
                var newS = new Shape(0, 0);
                var newR = new Ray(new Vector2(), new Vector2());
                
                result.set(newS, newR, 3, 5);
                result.shape.should.be(newS);
                result.ray.should.be(newR);
                result.start.should.be(3);
                result.end.should.be(5);
            });

            it('can get the start position along the line', {
                var ray = new Ray(new Vector2(2, 2), new Vector2(12, 12));
                var col = new RayCollision(mock(Shape), ray, 2, 6);

                RayCollisionHelper.hitStartX(col).should.be(22);
                RayCollisionHelper.hitStartY(col).should.be(22);
            });

            it('can get the end position along the line', {
                var ray = new Ray(new Vector2(2, 2), new Vector2(12, 12));
                var col = new RayCollision(mock(Shape), ray, 2, 6);

                RayCollisionHelper.hitEndX(col).should.be(62);
                RayCollisionHelper.hitEndY(col).should.be(62);
            });
        });
    }
}
