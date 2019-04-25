package tests.modules.differ.data;

import uk.aidanlee.flurry.modules.differ.shapes.Ray;
import uk.aidanlee.flurry.modules.differ.data.RayIntersection;
import buddy.BuddySuite;
import mockatoo.Mockatoo.mock;

using buddy.Should;

class RayIntersectionTests extends BuddySuite
{
    public function new()
    {
        describe('RayIntersectionTests', {
            it('can copy its values from another ray intersection', {
                var result1 = new RayIntersection();
                var result2 = new RayIntersection();
                result1.ray1 = mock(Ray);
                result1.ray2 = mock(Ray);
                result1.u1 = 2;
                result1.u2 = 6;

                result2.copy_from(result1);

                result2.ray1.should.be(result1.ray1);
                result2.ray2.should.be(result1.ray2);
                result2.u1.should.be(result1.u1);
                result2.u2.should.be(result1.u2);
            });

            it('can create a recursive clone of itself', {
                var result1 = new RayIntersection();
                result1.ray1 = mock(Ray);
                result1.ray2 = mock(Ray);
                result1.u1 = 2;
                result1.u2 = 6;

                var result2 = result1.clone();
                result2.ray1.should.be(result1.ray1);
                result2.ray2.should.be(result1.ray2);
                result2.u1.should.be(result1.u1);
                result2.u2.should.be(result1.u2);

                result2.u1 = 3;
                result2.u2 = 5;

                result2.ray1.should.be(result1.ray1);
                result2.ray2.should.be(result1.ray2);
                result2.u1.should.not.be(result1.u1);
                result2.u2.should.not.be(result1.u2);
            });
        });
    }
}
