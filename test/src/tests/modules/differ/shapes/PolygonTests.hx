package tests.modules.differ.shapes;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.modules.differ.shapes.Polygon;
import buddy.BuddySuite;

using buddy.Should;

class PolygonTests extends BuddySuite
{
    public function new()
    {
        describe('PolygonTests', {
            it('contains a static function to quickly create an n-gon', {
                var p = Polygon.create(10, 12, 8, 10);
                p.vertices.length.should.be(8);
                p.x.should.be(10);
                p.y.should.be(12);
            });

            it('contains a static function to quickly create a centred rectangle', {
                var x = 10;
                var y = 12;
                var w = 20;
                var h = 16;

                var p = Polygon.rectangle(x, y, w, h);
                p.x.should.be(x);
                p.y.should.be(y);
                p.scaleX.should.be(1);
                p.scaleY.should.be(1);

                p.vertices.length.should.be(4);
                p.vertices[0].x.should.be(0 - (w / 2));
                p.vertices[0].y.should.be(0 - (h / 2));
                p.vertices[1].x.should.be(0 + (w / 2));
                p.vertices[1].y.should.be(0 - (h / 2));
                p.vertices[2].x.should.be(0 + (w / 2));
                p.vertices[2].y.should.be(0 + (h / 2));
                p.vertices[3].x.should.be(0 - (w / 2));
                p.vertices[3].y.should.be(0 + (h / 2));

                p.transformedVertices.length.should.be(4);
                p.transformedVertices[0].x.should.be(x - (w / 2));
                p.transformedVertices[0].y.should.be(y - (h / 2));
                p.transformedVertices[1].x.should.be(x + (w / 2));
                p.transformedVertices[1].y.should.be(y - (h / 2));
                p.transformedVertices[2].x.should.be(x + (w / 2));
                p.transformedVertices[2].y.should.be(y + (h / 2));
                p.transformedVertices[3].x.should.be(x - (w / 2));
                p.transformedVertices[3].y.should.be(y + (h / 2));
            });

            it('contains a static function to quickly create a non-centred rectangle', {
                var x = 10;
                var y = 12;
                var w = 20;
                var h = 16;

                var p = Polygon.rectangle(x, y, w, h, false);
                p.x.should.be(x);
                p.y.should.be(y);
                p.scaleX.should.be(1);
                p.scaleY.should.be(1);

                p.vertices.length.should.be(4);
                p.vertices[0].x.should.be(0);
                p.vertices[0].y.should.be(0);
                p.vertices[1].x.should.be(w);
                p.vertices[1].y.should.be(0);
                p.vertices[2].x.should.be(w);
                p.vertices[2].y.should.be(h);
                p.vertices[3].x.should.be(0);
                p.vertices[3].y.should.be(h);

                p.transformedVertices.length.should.be(4);
                p.transformedVertices[0].x.should.be(x);
                p.transformedVertices[0].y.should.be(y);
                p.transformedVertices[1].x.should.be(x + w);
                p.transformedVertices[1].y.should.be(y);
                p.transformedVertices[2].x.should.be(x + w);
                p.transformedVertices[2].y.should.be(y + h);
                p.transformedVertices[3].x.should.be(x);
                p.transformedVertices[3].y.should.be(y + h);
            });

            it('contains a static function to quickly create a centred square', {
                var x = 10;
                var y = 12;
                var s = 4;

                var p = Polygon.square(x, y, s);
                p.x.should.be(x);
                p.y.should.be(y);
                p.scaleX.should.be(1);
                p.scaleY.should.be(1);

                p.vertices.length.should.be(4);
                p.vertices[0].x.should.be(0 - (s / 2));
                p.vertices[0].y.should.be(0 - (s / 2));
                p.vertices[1].x.should.be(0 + (s / 2));
                p.vertices[1].y.should.be(0 - (s / 2));
                p.vertices[2].x.should.be(0 + (s / 2));
                p.vertices[2].y.should.be(0 + (s / 2));
                p.vertices[3].x.should.be(0 - (s / 2));
                p.vertices[3].y.should.be(0 + (s / 2));

                p.transformedVertices.length.should.be(4);
                p.transformedVertices[0].x.should.be(x - (s / 2));
                p.transformedVertices[0].y.should.be(y - (s / 2));
                p.transformedVertices[1].x.should.be(x + (s / 2));
                p.transformedVertices[1].y.should.be(y - (s / 2));
                p.transformedVertices[2].x.should.be(x + (s / 2));
                p.transformedVertices[2].y.should.be(y + (s / 2));
                p.transformedVertices[3].x.should.be(x - (s / 2));
                p.transformedVertices[3].y.should.be(y + (s / 2));
            });

            it('contains a static function to quickly create a non-centred square', {
                var x = 10;
                var y = 12;
                var s = 4;

                var p = Polygon.square(x, y, s, false);
                p.x.should.be(x);
                p.y.should.be(y);
                p.scaleX.should.be(1);
                p.scaleY.should.be(1);

                p.vertices.length.should.be(4);
                p.vertices[0].x.should.be(0);
                p.vertices[0].y.should.be(0);
                p.vertices[1].x.should.be(s);
                p.vertices[1].y.should.be(0);
                p.vertices[2].x.should.be(s);
                p.vertices[2].y.should.be(s);
                p.vertices[3].x.should.be(0);
                p.vertices[3].y.should.be(s);

                p.transformedVertices.length.should.be(4);
                p.transformedVertices[0].x.should.be(x);
                p.transformedVertices[0].y.should.be(y);
                p.transformedVertices[1].x.should.be(x + s);
                p.transformedVertices[1].y.should.be(y);
                p.transformedVertices[2].x.should.be(x + s);
                p.transformedVertices[2].y.should.be(y + s);
                p.transformedVertices[3].x.should.be(x);
                p.transformedVertices[3].y.should.be(y + s);
            });

            it('contains a static function to quickly create a triangle', {
                var x = 10;
                var y = 12;
                var r = 4;
                var t = Polygon.triangle(x, y, r);

                t.vertices.length.should.be(3);
                t.transformedVertices.length.should.be(3);
            });

            it('changing the position will update the transformed vertices', {
                var originalX = 10;
                var originalY = 12;
                var moveX     =  8;
                var moveY     = -2;
                var size      =  6;
                var square    = Polygon.square(originalX, originalY, size);

                // Initial transform.
                square.x.should.be(originalX);
                square.y.should.be(originalY);
                square.scaleX.should.be(1);
                square.scaleY.should.be(1);

                square.vertices.length.should.be(4);
                square.vertices[0].x.should.be(0 - (size / 2));
                square.vertices[0].y.should.be(0 - (size / 2));
                square.vertices[1].x.should.be(0 + (size / 2));
                square.vertices[1].y.should.be(0 - (size / 2));
                square.vertices[2].x.should.be(0 + (size / 2));
                square.vertices[2].y.should.be(0 + (size / 2));
                square.vertices[3].x.should.be(0 - (size / 2));
                square.vertices[3].y.should.be(0 + (size / 2));

                square.transformedVertices.length.should.be(4);
                square.transformedVertices[0].x.should.be(originalX - (size / 2));
                square.transformedVertices[0].y.should.be(originalY - (size / 2));
                square.transformedVertices[1].x.should.be(originalX + (size / 2));
                square.transformedVertices[1].y.should.be(originalY - (size / 2));
                square.transformedVertices[2].x.should.be(originalX + (size / 2));
                square.transformedVertices[2].y.should.be(originalY + (size / 2));
                square.transformedVertices[3].x.should.be(originalX - (size / 2));
                square.transformedVertices[3].y.should.be(originalY + (size / 2));

                // Second transform.
                square.x += moveX;
                square.y += moveY;

                square.x.should.be(originalX + moveX);
                square.y.should.be(originalY + moveY);
                square.scaleX.should.be(1);
                square.scaleY.should.be(1);

                square.vertices.length.should.be(4);
                square.vertices[0].x.should.be(0 - (size / 2));
                square.vertices[0].y.should.be(0 - (size / 2));
                square.vertices[1].x.should.be(0 + (size / 2));
                square.vertices[1].y.should.be(0 - (size / 2));
                square.vertices[2].x.should.be(0 + (size / 2));
                square.vertices[2].y.should.be(0 + (size / 2));
                square.vertices[3].x.should.be(0 - (size / 2));
                square.vertices[3].y.should.be(0 + (size / 2));

                square.transformedVertices.length.should.be(4);
                square.transformedVertices[0].x.should.be((originalX + moveX) - (size / 2));
                square.transformedVertices[0].y.should.be((originalY + moveY) - (size / 2));
                square.transformedVertices[1].x.should.be((originalX + moveX) + (size / 2));
                square.transformedVertices[1].y.should.be((originalY + moveY) - (size / 2));
                square.transformedVertices[2].x.should.be((originalX + moveX) + (size / 2));
                square.transformedVertices[2].y.should.be((originalY + moveY) + (size / 2));
                square.transformedVertices[3].x.should.be((originalX + moveX) - (size / 2));
                square.transformedVertices[3].y.should.be((originalY + moveY) + (size / 2));
            });

            it('changing the scale will update the transformed vertices', {
                var x = 10;
                var y = 12;
                var newScaleX =  2;
                var newScaleY = -0.5;
                var size      =  6;
                var square    = Polygon.square(x, y, size);

                // Initial transform.
                square.x.should.be(x);
                square.y.should.be(y);
                square.scaleX.should.be(1);
                square.scaleY.should.be(1);

                square.vertices.length.should.be(4);
                square.vertices[0].x.should.be(0 - (size / 2));
                square.vertices[0].y.should.be(0 - (size / 2));
                square.vertices[1].x.should.be(0 + (size / 2));
                square.vertices[1].y.should.be(0 - (size / 2));
                square.vertices[2].x.should.be(0 + (size / 2));
                square.vertices[2].y.should.be(0 + (size / 2));
                square.vertices[3].x.should.be(0 - (size / 2));
                square.vertices[3].y.should.be(0 + (size / 2));

                square.transformedVertices.length.should.be(4);
                square.transformedVertices[0].x.should.be(x - (size / 2));
                square.transformedVertices[0].y.should.be(y - (size / 2));
                square.transformedVertices[1].x.should.be(x + (size / 2));
                square.transformedVertices[1].y.should.be(y - (size / 2));
                square.transformedVertices[2].x.should.be(x + (size / 2));
                square.transformedVertices[2].y.should.be(y + (size / 2));
                square.transformedVertices[3].x.should.be(x - (size / 2));
                square.transformedVertices[3].y.should.be(y + (size / 2));

                // Second transform.
                square.scaleX = newScaleX;
                square.scaleY = newScaleY;

                square.x.should.be(x);
                square.y.should.be(y);
                square.scaleX.should.be(newScaleX);
                square.scaleY.should.be(newScaleY);

                square.vertices.length.should.be(4);
                square.vertices[0].x.should.be(0 - (size / 2));
                square.vertices[0].y.should.be(0 - (size / 2));
                square.vertices[1].x.should.be(0 + (size / 2));
                square.vertices[1].y.should.be(0 - (size / 2));
                square.vertices[2].x.should.be(0 + (size / 2));
                square.vertices[2].y.should.be(0 + (size / 2));
                square.vertices[3].x.should.be(0 - (size / 2));
                square.vertices[3].y.should.be(0 + (size / 2));

                square.transformedVertices.length.should.be(4);
                square.transformedVertices[0].x.should.be(x - ((size / 2) * newScaleX));
                square.transformedVertices[0].y.should.be(y - ((size / 2) * newScaleY));
                square.transformedVertices[1].x.should.be(x + ((size / 2) * newScaleX));
                square.transformedVertices[1].y.should.be(y - ((size / 2) * newScaleY));
                square.transformedVertices[2].x.should.be(x + ((size / 2) * newScaleX));
                square.transformedVertices[2].y.should.be(y + ((size / 2) * newScaleY));
                square.transformedVertices[3].x.should.be(x - ((size / 2) * newScaleX));
                square.transformedVertices[3].y.should.be(y + ((size / 2) * newScaleY));
            });

            it('changing the angle will update the transformed vertices', {
                var x = 10;
                var y = 12;
                var s =  6;
                var r = 45;
                var square = Polygon.square(x, y, s);

                // Initial transform.
                square.x.should.be(x);
                square.y.should.be(y);
                square.scaleX.should.be(1);
                square.scaleY.should.be(1);

                square.vertices.length.should.be(4);
                square.vertices[0].x.should.be(0 - (s / 2));
                square.vertices[0].y.should.be(0 - (s / 2));
                square.vertices[1].x.should.be(0 + (s / 2));
                square.vertices[1].y.should.be(0 - (s / 2));
                square.vertices[2].x.should.be(0 + (s / 2));
                square.vertices[2].y.should.be(0 + (s / 2));
                square.vertices[3].x.should.be(0 - (s / 2));
                square.vertices[3].y.should.be(0 + (s / 2));

                square.transformedVertices.length.should.be(4);
                square.transformedVertices[0].x.should.be(x - (s / 2));
                square.transformedVertices[0].y.should.be(y - (s / 2));
                square.transformedVertices[1].x.should.be(x + (s / 2));
                square.transformedVertices[1].y.should.be(y - (s / 2));
                square.transformedVertices[2].x.should.be(x + (s / 2));
                square.transformedVertices[2].y.should.be(y + (s / 2));
                square.transformedVertices[3].x.should.be(x - (s / 2));
                square.transformedVertices[3].y.should.be(y + (s / 2));

                // after rotation
                square.rotation = r;

                square.x.should.be(x);
                square.y.should.be(y);
                square.scaleX.should.be(1);
                square.scaleY.should.be(1);

                square.vertices.length.should.be(4);
                square.vertices[0].x.should.be(0 - (s / 2));
                square.vertices[0].y.should.be(0 - (s / 2));
                square.vertices[1].x.should.be(0 + (s / 2));
                square.vertices[1].y.should.be(0 - (s / 2));
                square.vertices[2].x.should.be(0 + (s / 2));
                square.vertices[2].y.should.be(0 + (s / 2));
                square.vertices[3].x.should.be(0 - (s / 2));
                square.vertices[3].y.should.be(0 + (s / 2));

                var m = new Matrix().makeRotationZ(Maths.toRadians(45)).setPosition(new Vector(x, y));
                var v = new Vector();
                for (i in 0...square.transformedVertices.length)
                {
                    v.copyFrom(square.vertices[i]);
                    v.transform(m);
                    v.equals(square.transformedVertices[i]).should.be(true);
                }
            });
        });
    }
}
