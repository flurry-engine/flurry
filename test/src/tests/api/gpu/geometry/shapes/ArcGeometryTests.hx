package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.shapes.ArcGeometry;
import buddy.BuddySuite;

using buddy.Should;

class ArcGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('ArcGeometry', {
            it('Can create an arc geometry from circle options', {
                var g = new ArcGeometry({ startAngle : 45, endAngle : 270 });
                g.vertices.length.should.be(54);
            });
        });
    }
}
