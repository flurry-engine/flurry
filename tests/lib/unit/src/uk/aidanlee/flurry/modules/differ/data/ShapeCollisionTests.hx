package tests.modules.differ.data;

import uk.aidanlee.flurry.modules.differ.shapes.Shape;
import uk.aidanlee.flurry.modules.differ.data.ShapeCollision;
import buddy.BuddySuite;
import mockatoo.Mockatoo.mock;

using buddy.Should;

class ShapeCollisionTests extends BuddySuite
{
    public function new()
    {
        describe('ShapeCollisionTests', {
            it('can copy its values from another shape collision', {
                var result1 = new ShapeCollision(null, null, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
                var result2 = new ShapeCollision(null, null, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

                result2.copyFrom(result1);
                result2.overlap.should.be(result1.overlap);
                result2.separationX.should.be(result1.separationX);
                result2.separationY.should.be(result1.separationY);
                result2.unitVectorX.should.be(result1.unitVectorX);
                result2.unitVectorY.should.be(result1.unitVectorY);
                result2.otherOverlap.should.be(result1.otherOverlap);
                result2.otherSeparationX.should.be(result1.otherSeparationX);
                result2.otherSeparationY.should.be(result1.otherSeparationY);
                result2.otherUnitVectorX.should.be(result1.otherUnitVectorX);
                result2.otherUnitVectorY.should.be(result1.otherUnitVectorY);
            });

            it('can create a recursive clone of itself', {
                var result1 = new ShapeCollision(null, null, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
                var result2 = result1.clone();
                result2.shape1.should.be(result1.shape1);
                result2.shape2.should.be(result1.shape2);
                result2.overlap.should.be(result1.overlap);
                result2.separationX.should.be(result1.separationX);
                result2.separationY.should.be(result1.separationY);
                result2.unitVectorX.should.be(result1.unitVectorX);
                result2.unitVectorY.should.be(result1.unitVectorY);
                result2.otherOverlap.should.be(result1.otherOverlap);
                result2.otherSeparationX.should.be(result1.otherSeparationX);
                result2.otherSeparationY.should.be(result1.otherSeparationY);
                result2.otherUnitVectorX.should.be(result1.otherUnitVectorX);
                result2.otherUnitVectorY.should.be(result1.otherUnitVectorY);

                result1.set(result1.shape1, result1.shape2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

                result2.shape1.should.be(result1.shape1);
                result2.shape2.should.be(result1.shape2);
                result2.overlap.should.not.be(result1.overlap);
                result2.separationX.should.not.be(result1.separationX);
                result2.separationY.should.not.be(result1.separationY);
                result2.unitVectorX.should.not.be(result1.unitVectorX);
                result2.unitVectorY.should.not.be(result1.unitVectorY);
                result2.otherOverlap.should.not.be(result1.otherOverlap);
                result2.otherSeparationX.should.not.be(result1.otherSeparationX);
                result2.otherSeparationY.should.not.be(result1.otherSeparationY);
                result2.otherUnitVectorX.should.not.be(result1.otherUnitVectorX);
                result2.otherUnitVectorY.should.not.be(result1.otherUnitVectorY);
            });
        });
    }
}