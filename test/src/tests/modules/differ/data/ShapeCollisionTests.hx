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
                var result1 = new ShapeCollision();
                var result2 = new ShapeCollision();
                result1.shape1 = mock(Shape);
                result1.shape2 = mock(Shape);
                result1.overlap = 1;
                result1.separationX = 2;
                result1.separationY = 3;
                result1.unitVectorX = 4;
                result1.unitVectorY = 5;
                result1.otherOverlap = 6;
                result1.otherSeparationX = 7;
                result1.otherSeparationY = 8;
                result1.otherUnitVectorX = 9;
                result1.otherUnitVectorY = 10;

                result2.copy_from(result1);
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
                var result1 = new ShapeCollision();
                result1.shape1 = mock(Shape);
                result1.shape2 = mock(Shape);
                result1.overlap = 1;
                result1.separationX = 2;
                result1.separationY = 3;
                result1.unitVectorX = 4;
                result1.unitVectorY = 5;
                result1.otherOverlap = 6;
                result1.otherSeparationX = 7;
                result1.otherSeparationY = 8;
                result1.otherUnitVectorX = 9;
                result1.otherUnitVectorY = 10;

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

                result1.overlap = 2;
                result1.separationX = 3;
                result1.separationY = 4;
                result1.unitVectorX = 5;
                result1.unitVectorY = 6;
                result1.otherOverlap = 7;
                result1.otherSeparationX = 8;
                result1.otherSeparationY = 9;
                result1.otherUnitVectorX = 10;
                result1.otherUnitVectorY = 11;

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