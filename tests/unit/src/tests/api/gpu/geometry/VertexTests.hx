package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import buddy.BuddySuite;

using buddy.Should;

class VertexTests extends BuddySuite
{
    public function new()
    {
        describe('Vertex', {

            it('Can create a vertex from three vectors', {
                var pos = new Vector3(32, 32);
                var col = new Color(0.2, 0.2, 0.2, 1.0);
                var tex = new Vector2(1.0, 0.5);

                var vert = new Vertex(pos, col, tex);
                vert.position.equals(pos).should.be(true);
                vert.color   .equals(col).should.be(true);
                vert.texCoord.equals(tex).should.be(true);
            });

            it('Can copy its three components from another vector', {
                var pos = new Vector3(32, 32);
                var col = new Color(0.2, 0.2, 0.2, 1.0);
                var tex = new Vector2(1.0, 0.5);

                var v1 = new Vertex(pos, col, tex);
                var v2 = new Vertex(new Vector3(), new Color(), new Vector2());

                v1.position.equals(v2.position).should.not.be(true);
                v1.color   .equals(v2.color   ).should.not.be(true);
                v1.texCoord.equals(v2.texCoord).should.not.be(true);

                v2.copyFrom(v1);

                v1.position.equals(v2.position).should.be(true);
                v1.color   .equals(v2.color   ).should.be(true);
                v1.texCoord.equals(v2.texCoord).should.be(true);
            });

            it('Can clone itself and return a new independent vertex', {
                var pos = new Vector3(32, 32);
                var col = new Color(0.2, 0.2, 0.2, 1.0);
                var tex = new Vector2(1.0, 0.5);

                var v1 = new Vertex(pos, col, tex);
                var v2 = v1.clone();

                v2.position.equals(v1.position).should.be(true);
                v2.color   .equals(v1.color   ).should.be(true);
                v2.texCoord.equals(v1.texCoord).should.be(true);

                v2.position.set_xy(pos.x * 2, pos.y * 2);

                v2.position.equals(v1.position).should.not.be(true);
                v2.color   .equals(v1.color   ).should.be(true);
                v2.texCoord.equals(v1.texCoord).should.be(true);
            });

            it('Can check if another vertex is equal to it', {
                var pos = new Vector3(32, 32);
                var col = new Color(0.2, 0.2, 0.2, 1.0);
                var tex = new Vector2(1.0, 0.5);

                var v1 = new Vertex(pos, col, tex);
                var v2 = v1.clone();

                v2.equals(v1).should.be(true);
                v2.position.set_xy(pos.x * 2, pos.y * 2);
                v2.equals(v1).should.not.be(true);
            });
        });
    }
}
