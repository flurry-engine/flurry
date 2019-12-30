package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.textures.ImageRegion;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import mockatoo.Mockatoo.*;
import buddy.BuddySuite;

using mockatoo.Mockatoo;
using buddy.Should;

class QuadGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('QuadGeometry', {

            var texture = mock(ImageResource);
            var batcher = new Batcher({
                camera : mock(Camera),
                shader : mock(ShaderResource)
            });

            texture.width.returns(256);
            texture.height.returns(128);

            it('Creates an indexed quad with the textures size by default', {
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.vertices.length.should.be(4);
                
                quad.vertices[0].position.x.should.be(0);
                quad.vertices[0].position.y.should.be(texture.height);
                quad.vertices[1].position.x.should.be(texture.width);
                quad.vertices[1].position.y.should.be(texture.height);
                quad.vertices[2].position.x.should.be(0);
                quad.vertices[2].position.y.should.be(0);
                quad.vertices[3].position.x.should.be(texture.width);
                quad.vertices[3].position.y.should.be(0);

                quad.vertices[0].texCoord.x.should.be(0);
                quad.vertices[0].texCoord.y.should.be(1);
                quad.vertices[1].texCoord.x.should.be(1);
                quad.vertices[1].texCoord.y.should.be(1);
                quad.vertices[2].texCoord.x.should.be(0);
                quad.vertices[2].texCoord.y.should.be(0);
                quad.vertices[3].texCoord.x.should.be(1);
                quad.vertices[3].texCoord.y.should.be(0);

                for (i in 0...quad.vertices.length)
                {
                    quad.vertices[i].color.r.should.be(1);
                    quad.vertices[i].color.r.should.be(1);
                    quad.vertices[i].color.r.should.be(1);
                    quad.vertices[i].color.r.should.be(1);
                }

                quad.indices.length.should.be(6);
                quad.indices.should.containExactly([ 0, 1, 2, 2, 1, 3 ]);
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

                quad.vertices.length.should.be(4);
                quad.vertices[0].position.x.should.be(0);
                quad.vertices[0].position.y.should.be(height);
                quad.vertices[1].position.x.should.be(width);
                quad.vertices[1].position.y.should.be(height);
                quad.vertices[2].position.x.should.be(0);
                quad.vertices[2].position.y.should.be(0);
                quad.vertices[3].position.x.should.be(width);
                quad.vertices[3].position.y.should.be(0);
            });

            it('Will UV the entire texture by default', {
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.vertices.length.should.be(4);
                quad.vertices[0].texCoord.x.should.be(0);
                quad.vertices[0].texCoord.y.should.be(1);
                quad.vertices[1].texCoord.x.should.be(1);
                quad.vertices[1].texCoord.y.should.be(1);
                quad.vertices[2].texCoord.x.should.be(0);
                quad.vertices[2].texCoord.y.should.be(0);
                quad.vertices[3].texCoord.x.should.be(1);
                quad.vertices[3].texCoord.y.should.be(0);
            });

            it('Allows a custom UV region to be specified', {
                var uv = new Rectangle(
                    16 / texture.width,
                    48 / texture.height,
                    (16 + 32) / texture.width,
                    (48 + 64) / texture.height);

                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ],
                    region   : new ImageRegion(texture, 16, 48, 32, 64)
                });

                quad.vertices.length.should.be(4);
                quad.vertices[0].texCoord.x.should.beCloseTo(uv.x);
                quad.vertices[0].texCoord.y.should.beCloseTo(uv.h);
                quad.vertices[1].texCoord.x.should.beCloseTo(uv.w);
                quad.vertices[1].texCoord.y.should.beCloseTo(uv.h);
                quad.vertices[2].texCoord.x.should.beCloseTo(uv.x);
                quad.vertices[2].texCoord.y.should.beCloseTo(uv.y);
                quad.vertices[3].texCoord.x.should.beCloseTo(uv.w);
                quad.vertices[3].texCoord.y.should.beCloseTo(uv.y);
            });

            it('Allows resizing the quad using a vector', {
                var size = new Vector2(128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.resize(size);
                quad.vertices.length.should.be(4);
                quad.vertices[0].position.x.should.beCloseTo(0);
                quad.vertices[0].position.y.should.beCloseTo(size.y);
                quad.vertices[1].position.x.should.beCloseTo(size.x);
                quad.vertices[1].position.y.should.beCloseTo(size.y);
                quad.vertices[2].position.x.should.beCloseTo(0);
                quad.vertices[2].position.y.should.beCloseTo(0);
                quad.vertices[3].position.x.should.beCloseTo(size.x);
                quad.vertices[3].position.y.should.beCloseTo(0);
            });

            it('Allows resizing the quad using two floats', {
                var size = new Vector2(128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.resize_xy(size.x, size.y);
                quad.vertices.length.should.be(4);
                quad.vertices[0].position.x.should.beCloseTo(0);
                quad.vertices[0].position.y.should.beCloseTo(size.y);
                quad.vertices[1].position.x.should.beCloseTo(size.x);
                quad.vertices[1].position.y.should.beCloseTo(size.y);
                quad.vertices[2].position.x.should.beCloseTo(0);
                quad.vertices[2].position.y.should.beCloseTo(0);
                quad.vertices[3].position.x.should.beCloseTo(size.x);
                quad.vertices[3].position.y.should.beCloseTo(0);
            });

            it('Allows resizing and setting the position of the quad using a rectangle', {
                var rect = new Rectangle(32, 64, 128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.set(rect);
                quad.vertices.length.should.be(4);
                quad.vertices[0].position.x.should.beCloseTo(0);
                quad.vertices[0].position.y.should.beCloseTo(rect.h);
                quad.vertices[1].position.x.should.beCloseTo(rect.w);
                quad.vertices[1].position.y.should.beCloseTo(rect.h);
                quad.vertices[2].position.x.should.beCloseTo(0);
                quad.vertices[2].position.y.should.beCloseTo(0);
                quad.vertices[3].position.x.should.beCloseTo(rect.w);
                quad.vertices[3].position.y.should.beCloseTo(0);

                quad.transformation.position.x.should.beCloseTo(rect.x);
                quad.transformation.position.y.should.beCloseTo(rect.y);
            });

            it('Allows resizing and setting the position of the quad using four floats', {
                var rect = new Rectangle(32, 64, 128, 512);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.set_xywh(rect.x, rect.y, rect.w, rect.h);
                quad.vertices.length.should.be(4);
                quad.vertices[0].position.x.should.beCloseTo(0);
                quad.vertices[0].position.y.should.beCloseTo(rect.h);
                quad.vertices[1].position.x.should.beCloseTo(rect.w);
                quad.vertices[1].position.y.should.beCloseTo(rect.h);
                quad.vertices[2].position.x.should.beCloseTo(0);
                quad.vertices[2].position.y.should.beCloseTo(0);
                quad.vertices[3].position.x.should.beCloseTo(rect.w);
                quad.vertices[3].position.y.should.beCloseTo(0);

                quad.transformation.position.x.should.beCloseTo(rect.x);
                quad.transformation.position.y.should.beCloseTo(rect.y);
            });

            it('Allows setting normalized UV coordinates using a rectangle', {
                var rect = new Rectangle(0.2, 0.3, 0.8, 0.95);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv(rect);
                quad.vertices.length.should.be(4);

                quad.vertices[0].texCoord.x.should.beCloseTo(rect.x);
                quad.vertices[0].texCoord.y.should.beCloseTo(rect.h);

                quad.vertices[1].texCoord.x.should.beCloseTo(rect.w);
                quad.vertices[1].texCoord.y.should.beCloseTo(rect.h);

                quad.vertices[2].texCoord.x.should.beCloseTo(rect.x);
                quad.vertices[2].texCoord.y.should.beCloseTo(rect.y);

                quad.vertices[3].texCoord.x.should.beCloseTo(rect.w);
                quad.vertices[3].texCoord.y.should.beCloseTo(rect.y);
            });

            it('Allows setting normalized coordinates using four floats', {
                var rect = new Rectangle(0.2, 0.3, 0.8, 0.95);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv_xyzw(rect.x, rect.y, rect.w, rect.h);
                quad.vertices.length.should.be(4);

                quad.vertices[0].texCoord.x.should.beCloseTo(rect.x);
                quad.vertices[0].texCoord.y.should.beCloseTo(rect.h);

                quad.vertices[1].texCoord.x.should.beCloseTo(rect.w);
                quad.vertices[1].texCoord.y.should.beCloseTo(rect.h);

                quad.vertices[2].texCoord.x.should.beCloseTo(rect.x);
                quad.vertices[2].texCoord.y.should.beCloseTo(rect.y);

                quad.vertices[3].texCoord.x.should.beCloseTo(rect.w);
                quad.vertices[3].texCoord.y.should.beCloseTo(rect.y);
            });

            it('Allows setting texture space UV coordinates using a rectangle', {
                var rect = new Rectangle(32, 48, 96, 64);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv(rect, false);
                quad.vertices.length.should.be(4);

                quad.vertices[0].texCoord.x.should.beCloseTo(rect.x / texture.width);
                quad.vertices[0].texCoord.y.should.beCloseTo(rect.h / texture.height);

                quad.vertices[1].texCoord.x.should.beCloseTo(rect.w / texture.width);
                quad.vertices[1].texCoord.y.should.beCloseTo(rect.h / texture.height);

                quad.vertices[2].texCoord.x.should.beCloseTo(rect.x / texture.width);
                quad.vertices[2].texCoord.y.should.beCloseTo(rect.y / texture.height);

                quad.vertices[3].texCoord.x.should.beCloseTo(rect.w / texture.width);
                quad.vertices[3].texCoord.y.should.beCloseTo(rect.y / texture.height);
            });

            it('Allows setting texture space coordinates using four floats', {
                var rect = new Rectangle(32, 48, 96, 64);
                var quad = new QuadGeometry({
                    textures : [ texture ],
                    batchers : [ batcher ]
                });

                quad.uv_xyzw(rect.x, rect.y, rect.w, rect.h, false);
                quad.vertices.length.should.be(4);
                quad.vertices[0].texCoord.equals(new Vector2(rect.x / texture.width, rect.h / texture.height)).should.be(true);
                quad.vertices[1].texCoord.equals(new Vector2(rect.w / texture.width, rect.h / texture.height)).should.be(true);
                quad.vertices[2].texCoord.equals(new Vector2(rect.x / texture.width, rect.y / texture.height)).should.be(true);
                quad.vertices[3].texCoord.equals(new Vector2(rect.w / texture.width, rect.y / texture.height)).should.be(true);
            });
        });
    }
}
