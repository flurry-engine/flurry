package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.shapes.RingGeometry;
import buddy.BuddySuite;

using buddy.Should;

class RingGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('RingGeometry', {
            it('Can create a circle geometry with a unified radius', {
                var g = new RingGeometry({ r : 10 });
                g.vertices.length.should.be(30);
            });

            it('Can create a ring geometry with an x and y radius', {
                var g = new RingGeometry({ rx : 10, ry : 20 });
                g.vertices.length.should.be(44);
            });

            it('Can create a ring geometry with a start and end angle', {
                var g = new RingGeometry({ startAngle : 45, endAngle : 270 });
                g.vertices.length.should.be(56);
            });

            it('Can create a ring geometry with a specified smoothness', {
                var g = new RingGeometry({ smooth : 2 });
                g.vertices.length.should.be(22);
            });

            it('Can update all the ring geometries options from one function', {
                var g = new RingGeometry({ r : 10 });
                g.vertices.length.should.be(30);
                g.set(0, 0, 10, 20, 20);
                g.vertices.length.should.be(40);
            });
        });
    }
}
