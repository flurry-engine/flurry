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
                var result1 = new RayIntersection(mock(Ray), mock(Ray), 2, 6);
                var result2 = new RayIntersection(mock(Ray), mock(Ray), 0, 0);
                result2.copyFrom(result1);

                result2.ray1.should.be(result1.ray1);
                result2.ray2.should.be(result1.ray2);
                result2.u1.should.be(result1.u1);
                result2.u2.should.be(result1.u2);
            });

            it('can create a clone of itself', {
                var result1 = new RayIntersection(mock(Ray), mock(Ray), 2, 6);
                var result2 = result1.clone();
                result2.ray1.should.be(result1.ray1);
                result2.ray2.should.be(result1.ray2);
                result2.u1.should.be(result1.u1);
                result2.u2.should.be(result1.u2);
            });

            it('can update its values allowing re-use', {
                var result1 = new RayIntersection(mock(Ray), mock(Ray), 2, 6);
                var newR1 = mock(Ray);
                var newR2 = mock(Ray);
                
                result1.set(newR1, newR2, 3, 5);
                result1.ray1.should.be(newR1);
                result1.ray2.should.be(newR2);
                result1.u1.should.be(3);
                result1.u2.should.be(5);
            });
        });
    }
}
