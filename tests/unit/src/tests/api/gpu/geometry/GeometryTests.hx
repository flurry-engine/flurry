package tests.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class GeometryTests extends BuddySuite
{
    public function new()
    {
        describe('Geometry', {
            
            it('Has a unique identifier for each geometry instance', {
                var g1 = new Geometry({});
                var g2 = new Geometry({});
                var g3 = new Geometry({});

                g1.id.should.not.be(g2.id);
                g1.id.should.not.be(g3.id);

                g2.id.should.not.be(g1.id);
                g2.id.should.not.be(g3.id);

                g3.id.should.not.be(g1.id);
                g3.id.should.not.be(g2.id);
            });
            
            it('Has a transformation instance to modify its vertices', {
                var g = new Geometry({});
                g.transformation.position.equals(new Vector()).should.be(true);
                g.transformation.origin.equals(new Vector()).should.be(true);
                g.transformation.scale.equals(new Vector(1, 1, 1)).should.be(true);
                g.transformation.rotation.equals(new Quaternion()).should.be(true);
            });

            it('Has shortcut properties to access transformation data', {
                var g = new Geometry({});
                g.position.equals(g.transformation.position).should.be(true);
                g.origin.equals(g.transformation.origin).should.be(true);
                g.scale.equals(g.transformation.scale).should.be(true);
                g.rotation.equals(g.transformation.rotation).should.be(true);
            });

            it('Contains an array of vertices which makes up the geometry', {
                var v = [
                    new Vertex(new Vector(), new Color(), new Vector()),
                    new Vertex(new Vector(), new Color(), new Vector()),
                    new Vertex(new Vector(), new Color(), new Vector())
                ];

                var g = new Geometry({});
                g.vertices.should.containExactly([]);

                var g = new Geometry({ vertices : v });
                g.vertices.should.containExactly(v);
            });

            it('Contains an array of indices for indexed drawing', {
                var i = [ 0, 1, 2 ];

                var g = new Geometry({});
                g.indices.should.containExactly([]);

                var g = new Geometry({ indices : i });
                g.indices.should.containExactly(i);
            });

            it('Has a colour which the geometry is tinted by', {
                var c = new Color(0.5, 0.2, 0.8, 0.9);

                var g = new Geometry({});
                g.color.equals(new Color()).should.be(true);

                var g = new Geometry({ color : c });
                g.color.equals(c).should.be(true);
            });

            it('Has a clip rectangle for cutting off part of the geometry', {
                var r = new Rectangle(12, 4, 20, 7);

                var g = new Geometry({});
                g.clip.should.be(null);

                var g = new Geometry({ clip : r });
                g.clip.equals(r).should.be(true);
            });

            it('Has an array of textures to draw the geometry with', {
                var t = mock(ImageResource);

                var g = new Geometry({});
                g.textures.should.containExactly([]);

                var g = new Geometry({ textures : [ t ] });
                g.textures.should.containExactly([ t ]);
            });

            it('Has a shader for overriding the batchers shader', {
                var s = mock(ShaderResource);

                var g = new Geometry({});
                g.shader.should.be(null);

                var g = new Geometry({ shader : s });
                g.shader.should.be(s);
            });

            it('Has a uniform for overriding the shaders default', {
                var u = mock(Uniforms);

                var g = new Geometry({});
                g.uniforms.should.be(null);

                var g = new Geometry({ uniforms : u });
                g.uniforms.should.be(u);
            });

            it('Has a depth to decide when it should be drawn', {
                var g = new Geometry({});
                g.depth.should.be(0);

                var g = new Geometry({ depth : 5.2 });
                g.depth.should.be(5.2);
            });

            it('Has a primitive type to tell the renderer how to interpret the vertex data', {
                var g = new Geometry({});
                g.primitive.should.equal(Triangles);

                var g = new Geometry({ primitive : Points });
                g.primitive.should.equal(Points);
            });

            // it('Will dirty any batchers its in when adding a texture', {
            //     var u = mock(Uniforms);
            //     var s = mock(ShaderResource);
                
            //     u.id.returns(0);
            //     s.id.returns(0);
            //     s.uniforms.returns(u);

            //     var b = new Batcher({ shader : s, camera : mock(Camera) });
            //     var g = new Geometry({ batchers : [ b ] });

            //     // Batching is required to clear the dirty state set when the geometry was added.
            //     b.batch();
            //     g.addTexture(mock(ImageResource));

            //     b.isDirty().should.be(true);
            // });

            // it('Will dirty any batchers its in when removing a texture', {
            //     var u = mock(Uniforms);
            //     var s = mock(ShaderResource);
            //     var t = mock(ImageResource);
                
            //     u.id.returns(0);
            //     s.id.returns(0);
            //     s.uniforms.returns(u);
                
            //     var b = new Batcher({ shader : s, camera : mock(Camera) });
            //     var g = new Geometry({ batchers : [ b ], textures: [ t ] });

            //     // Batching is required to clear the dirty state set when the geometry was added.
            //     b.batch();
            //     g.removeTexture(t);

            //     b.isDirty().should.be(true);
            // });

            it('Will remove itself from any batchers when dropped', {
                var b = new Batcher({ shader : mock(ShaderResource), camera : mock(Camera) });

                var g1 = new Geometry({ batchers : [ b ] });
                var g2 = new Geometry({ batchers : [ b ] });

                b.geometry.should.containExactly([ g1, g2 ]);
                g1.drop();
                b.geometry.should.containExactly([ g2 ]);
            });

            it('Contains a convenience function to dirty all the batchers it is in', {
                var u = mock(Uniforms);
                var s = mock(ShaderResource);
                
                u.id.returns(0);
                s.id.returns(0);
                s.uniforms.returns(u);

                var b1 = new Batcher({ shader : s, camera : mock(Camera) });
                var b2 = new Batcher({ shader : s, camera : mock(Camera) });

                var g = new Geometry({ batchers : [ b1, b2 ] });

                // Batching is required to clear the dirty state set when the geometry was added.
                b1.batch();
                b2.batch();
                g.changed.dispatch();

                b1.isDirty().should.be(true);
                b2.isDirty().should.be(true);
            });

            it('Contains a convenience function to check if the geometry is indexed', {
                var g = new Geometry({ indices : [ 0, 1, 2 ] });
                g.isIndexed().should.be(true);

                var g = new Geometry({});
                g.isIndexed().should.be(false);
            });

            describe('firing the dirty signal when properties change', {
                it('will fire the signal when the shader is changed', {
                    var c = 0;
                    var s = mock(ShaderResource);
                    var g = new Geometry({});
                    g.changed.add(() -> c++);

                    g.shader = s;
                    c.should.be(1);
                });
                it('will fire the signal when the unfiroms are changed', {
                    var c = 0;
                    var u = mock(Uniforms);
                    var g = new Geometry({});
                    g.changed.add(() -> c++);

                    g.uniforms = u;
                    c.should.be(1);
                });
                it('will fire the signal when the depth is changed', {
                    var c = 0;
                    var g = new Geometry({});
                    g.changed.add(() -> c++);

                    g.depth = 8;
                    c.should.be(1);
                });
                it('will fire the signal when the primitive is changed', {
                    var c = 0;
                    var g = new Geometry({});
                    g.changed.add(() -> c++);

                    g.primitive = Points;
                    c.should.be(1);
                });
            });
        });
    }
}
