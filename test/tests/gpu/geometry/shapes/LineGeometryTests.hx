package tests.gpu.geometry.shapes;

import uk.aidanlee.maths.Vector;
import uk.aidanlee.gpu.geometry.shapes.LineGeometry;
import uk.aidanlee.gpu.geometry.Color;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class LineGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('LineGeometry', {
            it('Can create a line geometry with default settings', {
                var geom = new LineGeometry({});
                geom.vertices.length.should.be(2);
                geom.vertices[0].position.equals(geom.point0).should.be(true);
                geom.vertices[1].position.equals(geom.point1).should.be(true);
                geom.vertices[0].color.equals(geom.color0).should.be(true);
                geom.vertices[1].color.equals(geom.color1).should.be(true);
            });

            it('Can create a line geometry with custom settings', {
                var p0 = new Vector( 32, 48);
                var p1 = new Vector(256, 90);
                var c0 = new Color(0.2, 0.3, 0.4, 1.0);
                var c1 = new Color(0.5, 0.6, 0.2, 8.0);

                var geom = new LineGeometry({
                    point0 : p0,
                    point1 : p1,
                    color0 : c0,
                    color1 : c1
                });
                geom.vertices.length.should.be(2);
                geom.point0.equals(p0).should.be(true);
                geom.point1.equals(p1).should.be(true);
                geom.color0.equals(c0).should.be(true);
                geom.color1.equals(c1).should.be(true);
                geom.vertices[0].position.equals(geom.point0).should.be(true);
                geom.vertices[1].position.equals(geom.point1).should.be(true);
                geom.vertices[0].color.equals(geom.color0).should.be(true);
                geom.vertices[1].color.equals(geom.color1).should.be(true);
            });
        });
    }
}
