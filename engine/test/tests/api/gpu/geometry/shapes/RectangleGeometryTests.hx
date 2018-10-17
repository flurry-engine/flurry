package tests.gpu.api.geometry.shapes;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.RectangleGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import mockatoo.Mockatoo.*;
import buddy.BuddySuite;

using mockatoo.Mockatoo;
using buddy.Should;

class RectangleGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('RectangleGeometry', {
            var batcher = new Batcher({
                camera : mock(Camera),
                shader : mock(ShaderResource)
            });

            it('Can create the geometry with a default size', {
                var rectangle = new RectangleGeometry({
                    batchers : [ batcher ]
                });

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(1, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(1, 1)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, 1)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);
            });

            it('Can create the geometry from four floats', {
                var x =  32;
                var y =  48;
                var w = 128;
                var h =  64;

                var rectangle = new RectangleGeometry({
                    x : x, y : y, w : w, h : h,
                    batchers : [ batcher ]
                });

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(w, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(w, h)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, h)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);

                rectangle.transformation.position.equals(new Vector(x, y)).should.be(true);
            });

            it('Can create the geometry from a rectangle', {
                var x =  32;
                var y =  48;
                var w = 128;
                var h =  64;

                var rectangle = new RectangleGeometry({
                    r : new Rectangle(x, y, w, h),
                    batchers : [ batcher ]
                });

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(w, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(w, h)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, h)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);

                rectangle.transformation.position.equals(new Vector(x, y)).should.be(true);
            });

            it('Can resize the geometry from a vector', {
                var w = 32;
                var h = 48;

                var rectangle = new RectangleGeometry({
                    batchers : [ batcher ]
                });

                rectangle.resize(new Vector(w, h));

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(w, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(w, h)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, h)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);
            });

            it('Can resize the geometry from two floats', {
                var w = 32;
                var h = 48;

                var rectangle = new RectangleGeometry({
                    batchers : [ batcher ]
                });

                rectangle.resize_xy(w, h);

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(w, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(w, h)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, h)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);
            });

            it('Can resize and set the position of the geometry from a rectangle', {
                var x =  32;
                var y =  48;
                var w = 128;
                var h =  64;

                var rectangle = new RectangleGeometry({
                    batchers : [ batcher ]
                });

                rectangle.set(new Rectangle(x, y, w, h));

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(w, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(w, h)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, h)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);

                rectangle.transformation.position.equals(new Vector(x, y)).should.be(true);
            });

            it('Can resize and set the position of the geometry from four floats', {
                var x =  32;
                var y =  48;
                var w = 128;
                var h =  64;

                var rectangle = new RectangleGeometry({
                    batchers : [ batcher ]
                });

                rectangle.set_xywh(x, y, w, h);

                rectangle.vertices[0].position.equals(new Vector(0, 0)).should.be(true);
                rectangle.vertices[1].position.equals(new Vector(w, 0)).should.be(true);
                rectangle.vertices[2].position.equals(new Vector(w, h)).should.be(true);
                rectangle.vertices[3].position.equals(new Vector(0, h)).should.be(true);
                rectangle.vertices[4].equals(rectangle.vertices[0]);

                rectangle.transformation.position.equals(new Vector(x, y)).should.be(true);
            });
        });
    }
}
