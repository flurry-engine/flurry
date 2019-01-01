package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.geometry.Transformation;
import buddy.BuddySuite;

using buddy.Should;

class TransformationTests extends BuddySuite
{
    public function new()
    {
        describe('Transformation', {
            it('Creates a transformation at 0x0, scale of 1, 0 radians rotation, and origin of 0x0', {
                var transformation = new Transformation();
                transformation.position.equals(new Vector()).should.be(true);
                transformation.origin.equals(new Vector()).should.be(true);
                transformation.scale.equals(new Vector(1, 1, 1)).should.be(true);
                transformation.rotation.equals(new Quaternion()).should.be(true);
            });

            it('Contains a transformation property which contains a matrix composed of all the individual transformations', {
                var transformation = new Transformation();
                transformation.transformation.should.not.be(null);
            });
        });
    }
}
