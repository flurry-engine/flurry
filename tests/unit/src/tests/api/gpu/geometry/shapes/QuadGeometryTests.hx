package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import buddy.BuddySuite;

using buddy.Should;

class QuadGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('QuadGeometry', {
            it('Creates an indexed quad with the textures size by default', {
                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({ texture : texture });

                switch quad.data
                {
                    case Indexed(_vertices, _indices):
                        _vertices.buffer.byteLength.should.be(144);

                        _indices.buffer.byteLength.should.be(12);
                        _indices.shortAccess[0] = 0;
                        _indices.shortAccess[1] = 1;
                        _indices.shortAccess[2] = 2;
                        _indices.shortAccess[3] = 2;
                        _indices.shortAccess[4] = 0;
                        _indices.shortAccess[5] = 3;
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }
            });

            it('Can create a quad at a specific position', {
                final x = 128;
                final y =  64;

                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({ texture : texture, x : x, y : y });

                quad.transformation.position.x.should.be(x);
                quad.transformation.position.y.should.be(y);
            });

            it('Can create a quad with a specific size', {
                final width  = 128;
                final height =  64;

                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({
                    texture : texture,
                    width   : width,
                    height  : height
                });

                switch quad.data
                {
                    case Indexed(_vertices, _):
                        // vertex 1
                        // x, y, z
                        _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(0 * 9) + 1].should.be(height);

                        // vertex 2
                        // x, y, z
                        _vertices.floatAccess[(1 * 9) + 0].should.be(width);
                        _vertices.floatAccess[(1 * 9) + 1].should.be(height);

                        // vertex 3
                        // x, y, z
                        _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(2 * 9) + 1].should.be(0);

                        // vertex 4
                        // x, y, z
                        _vertices.floatAccess[(3 * 9) + 0].should.be(width);
                        _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }
            });

            it('Will UV the entire texture by default', {
                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({ texture : texture });

                switch quad.data
                {
                    case Indexed(_vertices, _):
                        // vertex 1
                        // u, v
                        _vertices.floatAccess[(0 * 9) + 7].should.be(0);
                        _vertices.floatAccess[(0 * 9) + 8].should.be(1);

                        // vertex 2
                        // u, v
                        _vertices.floatAccess[(1 * 9) + 7].should.be(1);
                        _vertices.floatAccess[(1 * 9) + 8].should.be(1);

                        // vertex 3
                        // u, v
                        _vertices.floatAccess[(2 * 9) + 7].should.be(0);
                        _vertices.floatAccess[(2 * 9) + 8].should.be(0);

                        // vertex 4
                        // u, v
                        _vertices.floatAccess[(3 * 9) + 7].should.be(1);
                        _vertices.floatAccess[(3 * 9) + 8].should.be(0);
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }
            });

            it('Allows a custom UV region to be specified', {
                final texture = new ImageFrameResource('', '', 16, 48, 32, 64, 16 / 256, 48 / 128, (16 + 32) / 256, (48 + 64) / 128);
                final quad    = new QuadGeometry({ texture : texture });

                switch quad.data
                {
                    case Indexed(_vertices, _):
                        // vertex 1
                        // u, v
                        _vertices.floatAccess[(0 * 9) + 7].should.be(texture.u1);
                        _vertices.floatAccess[(0 * 9) + 8].should.be(texture.v2);

                        // vertex 2
                        // u, v
                        _vertices.floatAccess[(1 * 9) + 7].should.be(texture.u2);
                        _vertices.floatAccess[(1 * 9) + 8].should.be(texture.v2);

                        // vertex 3
                        // u, v
                        _vertices.floatAccess[(2 * 9) + 7].should.be(texture.u1);
                        _vertices.floatAccess[(2 * 9) + 8].should.be(texture.v1);

                        // vertex 4
                        // u, v
                        _vertices.floatAccess[(3 * 9) + 7].should.be(texture.u2);
                        _vertices.floatAccess[(3 * 9) + 8].should.be(texture.v1);
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }
            });

            it('Allows resizing the quad using two floats', {
                final width = 128;
                final height = 512;

                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({ texture : texture });

                quad.resize(width, height);

                switch quad.data
                {
                    case Indexed(_vertices, _):
                        // vertex 1
                        // x, y, z
                        _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(0 * 9) + 1].should.be(height);

                        // vertex 2
                        // x, y, z
                        _vertices.floatAccess[(1 * 9) + 0].should.be(width);
                        _vertices.floatAccess[(1 * 9) + 1].should.be(height);

                        // vertex 3
                        // x, y, z
                        _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(2 * 9) + 1].should.be(0);

                        // vertex 4
                        // x, y, z
                        _vertices.floatAccess[(3 * 9) + 0].should.be(width);
                        _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }
            });

            it('Allows resizing and setting the position of the quad using four floats', {
                final x = 32;
                final y = 48;
                final width = 128;
                final height = 512;

                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({ texture : texture });

                quad.set(x, y, width, height);

                switch quad.data
                {
                    case Indexed(_vertices, _):
                        // vertex 1
                        // x, y, z
                        _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(0 * 9) + 1].should.be(height);

                        // vertex 2
                        // x, y, z
                        _vertices.floatAccess[(1 * 9) + 0].should.be(width);
                        _vertices.floatAccess[(1 * 9) + 1].should.be(height);

                        // vertex 3
                        // x, y, z
                        _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(2 * 9) + 1].should.be(0);

                        // vertex 4
                        // x, y, z
                        _vertices.floatAccess[(3 * 9) + 0].should.be(width);
                        _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }

                quad.transformation.position.x.should.be(x);
                quad.transformation.position.y.should.be(y);
            });

            it('Allows setting normalized coordinates using four floats', {
                final x = 0.2;
                final y = 0.3;
                final w = 0.8;
                final h = 0.95;

                final texture = new ImageFrameResource('', '', 0, 0, 256, 128, 0, 0, 1, 1);
                final quad    = new QuadGeometry({ texture : texture });

                quad.uv(x, y, w, h);

                switch quad.data
                {
                    case Indexed(_vertices, _):
                        // vertex 1
                        // u, v
                        _vertices.floatAccess[(0 * 9) + 7].should.beCloseTo(x);
                        _vertices.floatAccess[(0 * 9) + 8].should.beCloseTo(h);

                        // vertex 2
                        // u, v
                        _vertices.floatAccess[(1 * 9) + 7].should.beCloseTo(w);
                        _vertices.floatAccess[(1 * 9) + 8].should.beCloseTo(h);

                        // vertex 3
                        // u, v
                        _vertices.floatAccess[(2 * 9) + 7].should.beCloseTo(x);
                        _vertices.floatAccess[(2 * 9) + 8].should.beCloseTo(y);

                        // vertex 4
                        // u, v
                        _vertices.floatAccess[(3 * 9) + 7].should.beCloseTo(w);
                        _vertices.floatAccess[(3 * 9) + 8].should.beCloseTo(y);
                    case UnIndexed(_):
                        fail('quad data should be indexed');
                }
            });

            describe('Updating the frame', {
                final frame1 = new ImageFrameResource('frame_1', 'image', 0, 0, 256, 128, 0, 0, 1, 1);
                final frame2 = new ImageFrameResource('frame_2', 'image', 0, 0,  64,  32, 0.2, 0.3, 0.75, 0.55);
                final quad   = new QuadGeometry({ texture : frame1 });

                quad.reframe(frame2);

                it('will uv the geometry to the frame', {
                    switch quad.data
                    {
                        case Indexed(_vertices, _):
                        _vertices.floatAccess[(0 * 9) + 7].should.beCloseTo(frame2.u1);
                        _vertices.floatAccess[(0 * 9) + 8].should.beCloseTo(frame2.v2);

                        _vertices.floatAccess[(1 * 9) + 7].should.beCloseTo(frame2.u2);
                        _vertices.floatAccess[(1 * 9) + 8].should.beCloseTo(frame2.v2);

                        _vertices.floatAccess[(2 * 9) + 7].should.beCloseTo(frame2.u1);
                        _vertices.floatAccess[(2 * 9) + 8].should.beCloseTo(frame2.v1);

                        _vertices.floatAccess[(3 * 9) + 7].should.beCloseTo(frame2.u2);
                        _vertices.floatAccess[(3 * 9) + 8].should.beCloseTo(frame2.v1);
                        case _:
                            fail('quad data should be indexed');
                    }
                });
                it('will resize the geometry to the frame', {
                    switch quad.data
                    {
                        case Indexed(_vertices, _):
                        _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(0 * 9) + 1].should.be(frame2.height);

                        _vertices.floatAccess[(1 * 9) + 0].should.be(frame2.width);
                        _vertices.floatAccess[(1 * 9) + 1].should.be(frame2.height);

                        _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                        _vertices.floatAccess[(2 * 9) + 1].should.be(0);

                        _vertices.floatAccess[(3 * 9) + 0].should.be(frame2.width);
                        _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                        case _:
                            fail('quad data should be indexed');
                    }
                });
                it('will update the textures of the geometry', {
                    switch quad.textures
                    {
                        case Some(_frames):
                            _frames.length.should.be(1);
                            _frames[0].should.be(frame2.image);
                        case _:
                            fail('expected textures on this quad');
                    }
                });
            });
        });
    }
}
