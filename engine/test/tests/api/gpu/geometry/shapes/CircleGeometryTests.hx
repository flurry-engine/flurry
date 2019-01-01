package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.shapes.CircleGeometry;
import buddy.BuddySuite;

using buddy.Should;

class CircleGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('CircleGeometry', {
            it('Can create a circle geometry with a unified radius', {
                var g = new CircleGeometry({ r : 10 });
                g.vertices.length.should.be(48);
            });

            it('Can create a circle geometry with an x and y radius', {
                var g = new CircleGeometry({ rx : 10, ry : 20 });
                g.vertices.length.should.be(69);
            });

            it('Can create a circle geometry with a start and end angle', {
                var g = new CircleGeometry({ startAngle : 45, endAngle : 270 });
                g.vertices.length.should.be(57);
            });

            it('Can create a circle geometry with a specified smoothness', {
                var g = new CircleGeometry({ smooth : 2 });
                g.vertices.length.should.be(36);
            });

            it('Can update all the circle geometries options from one function', {
                var g = new CircleGeometry({ r : 10 });
                g.vertices.length.should.be(48);
                g.set(0, 0, 10, 20, 20);
                g.vertices.length.should.be(111);
            });
        });
    }
}
