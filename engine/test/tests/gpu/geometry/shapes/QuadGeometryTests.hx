package tests.gpu.geometry.shapes;

import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.gpu.Texture;
import uk.aidanlee.gpu.Shader;
import uk.aidanlee.gpu.camera.Camera;
import uk.aidanlee.gpu.batcher.Batcher;
import uk.aidanlee.gpu.geometry.shapes.QuadGeometry;
import mockatoo.Mockatoo.*;
import buddy.BuddySuite;

using mockatoo.Mockatoo;
using buddy.Should;

class QuadGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('QuadGeometry', {
            var texture = mock(Texture);
            var batcher = new Batcher({
                camera : mock(Camera),
                shader : mock(Shader)
            });

            texture.width.returns(256);
            texture.height.returns(128);

            it('Can create a quad the size of the provided texture', {
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.vertices[0].position.equals(new Vector(            0,              0)).should.be(true);
                quad.vertices[1].position.equals(new Vector(texture.width,              0)).should.be(true);
                quad.vertices[2].position.equals(new Vector(texture.width, texture.height)).should.be(true);

                quad.vertices[3].position.equals(new Vector(            0, texture.height)).should.be(true);
                quad.vertices[4].position.equals(new Vector(            0,              0)).should.be(true);
                quad.vertices[5].position.equals(new Vector(texture.width, texture.height)).should.be(true);
            });

            it('Can create a quad at a specific position', {
                var x = 128;
                var y =  64;

                var quad = new QuadGeometry({
                    x : x,
                    y : y,
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.transformation.position.x.should.be(x);
                quad.transformation.position.y.should.be(y);
            });

            it('Can create a quad with a specific size', {
                var width  = 128;
                var height =  64;

                var quad = new QuadGeometry({
                    w : width,
                    h : height,
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.vertices[0].position.equals(new Vector(    0,      0)).should.be(true);
                quad.vertices[1].position.equals(new Vector(width,      0)).should.be(true);
                quad.vertices[2].position.equals(new Vector(width, height)).should.be(true);

                quad.vertices[3].position.equals(new Vector(    0, height)).should.be(true);
                quad.vertices[4].position.equals(new Vector(    0,      0)).should.be(true);
                quad.vertices[5].position.equals(new Vector(width, height)).should.be(true);
            });

            it('Will UV the entire texture by default', {
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.vertices[0].texCoord.equals(new Vector(0, 0)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector(1, 0)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector(1, 1)).should.be(true);

                quad.vertices[3].texCoord.equals(new Vector(0, 1)).should.be(true);
                quad.vertices[4].texCoord.equals(new Vector(0, 0)).should.be(true);
                quad.vertices[5].texCoord.equals(new Vector(1, 1)).should.be(true);
            });

            it('Allows a custom UV region to be specified', {
                var uv = new Rectangle(0.25, 0.3, 0.8, 0.63);

                var quad = new QuadGeometry({
                    uv : uv,
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.vertices[0].texCoord.equals(new Vector(uv.x, uv.y)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector(uv.w, uv.y)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector(uv.w, uv.h)).should.be(true);

                quad.vertices[3].texCoord.equals(new Vector(uv.x, uv.h)).should.be(true);
                quad.vertices[4].texCoord.equals(new Vector(uv.x, uv.y)).should.be(true);
                quad.vertices[5].texCoord.equals(new Vector(uv.w, uv.h)).should.be(true);
            });

            it('Allows resizing the quad using a vector', {
                var size = new Vector(128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.resize(size);

                quad.vertices[0].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[1].position.equals(new Vector(size.x,      0)).should.be(true);
                quad.vertices[2].position.equals(new Vector(size.x, size.y)).should.be(true);

                quad.vertices[3].position.equals(new Vector(     0, size.y)).should.be(true);
                quad.vertices[4].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[5].position.equals(new Vector(size.x, size.y)).should.be(true);
            });

            it('Allows resizing the quad using two floats', {
                var size = new Vector(128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.resize_xy(size.x, size.y);

                quad.vertices[0].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[1].position.equals(new Vector(size.x,      0)).should.be(true);
                quad.vertices[2].position.equals(new Vector(size.x, size.y)).should.be(true);

                quad.vertices[3].position.equals(new Vector(     0, size.y)).should.be(true);
                quad.vertices[4].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[5].position.equals(new Vector(size.x, size.y)).should.be(true);
            });

            it('Allows resizing and setting the position of the quad using a rectangle', {
                var rect = new Rectangle(32, 64, 128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.set(rect);

                quad.vertices[0].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[1].position.equals(new Vector(rect.w,      0)).should.be(true);
                quad.vertices[2].position.equals(new Vector(rect.w, rect.h)).should.be(true);

                quad.vertices[3].position.equals(new Vector(     0, rect.h)).should.be(true);
                quad.vertices[4].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[5].position.equals(new Vector(rect.w, rect.h)).should.be(true);

                quad.transformation.position.equals(new Vector(rect.x, rect.y));
            });

            it('Allows resizing and setting the position of the quad using four floats', {
                var rect = new Rectangle(32, 64, 128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.set_xywh(rect.x, rect.y, rect.w, rect.h);

                quad.vertices[0].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[1].position.equals(new Vector(rect.w,      0)).should.be(true);
                quad.vertices[2].position.equals(new Vector(rect.w, rect.h)).should.be(true);

                quad.vertices[3].position.equals(new Vector(     0, rect.h)).should.be(true);
                quad.vertices[4].position.equals(new Vector(     0,      0)).should.be(true);
                quad.vertices[5].position.equals(new Vector(rect.w, rect.h)).should.be(true);

                quad.transformation.position.equals(new Vector(rect.x, rect.y));
            });

            it('Allows setting normalized UV coordinates using a rectangle', {
                var rect = new Rectangle(0.2, 0.3, 0.8, 0.95);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv(rect);

                quad.vertices[0].texCoord.equals(new Vector(rect.x, rect.y)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector(rect.w, rect.y)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector(rect.w, rect.h)).should.be(true);

                quad.vertices[3].texCoord.equals(new Vector(rect.x, rect.h)).should.be(true);
                quad.vertices[4].texCoord.equals(new Vector(rect.x, rect.y)).should.be(true);
                quad.vertices[5].texCoord.equals(new Vector(rect.w, rect.h)).should.be(true);
            });

            it('Allows setting normalized coordinates using four floats', {
                var rect = new Rectangle(0.2, 0.3, 0.8, 0.95);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv_xyzw(rect.x, rect.y, rect.w, rect.h);

                quad.vertices[0].texCoord.equals(new Vector(rect.x, rect.y)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector(rect.w, rect.y)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector(rect.w, rect.h)).should.be(true);

                quad.vertices[3].texCoord.equals(new Vector(rect.x, rect.h)).should.be(true);
                quad.vertices[4].texCoord.equals(new Vector(rect.x, rect.y)).should.be(true);
                quad.vertices[5].texCoord.equals(new Vector(rect.w, rect.h)).should.be(true);
            });

            it('Allows setting texture space UV coordinates using a rectangle', {
                var rect = new Rectangle(32, 48, 96, 64);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv(rect, false);

                quad.vertices[0].texCoord.equals(new Vector(rect.x / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector(rect.w / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector(rect.w / texture.width, rect.h / texture.height)).should.be(true);

                quad.vertices[3].texCoord.equals(new Vector(rect.x / texture.width, rect.h / texture.height)).should.be(true);
                quad.vertices[4].texCoord.equals(new Vector(rect.x / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[5].texCoord.equals(new Vector(rect.w / texture.width, rect.h / texture.height)).should.be(true);
            });

            it('Allows setting texture space coordinates using four floats', {
                var rect = new Rectangle(32, 48, 96, 64);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv_xyzw(rect.x, rect.y, rect.w, rect.h, false);

                quad.vertices[0].texCoord.equals(new Vector(rect.x / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector(rect.w / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector(rect.w / texture.width, rect.h / texture.height)).should.be(true);

                quad.vertices[3].texCoord.equals(new Vector(rect.x / texture.width, rect.h / texture.height)).should.be(true);
                quad.vertices[4].texCoord.equals(new Vector(rect.x / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[5].texCoord.equals(new Vector(rect.w / texture.width, rect.h / texture.height)).should.be(true);
            });
        });
    }
}
