package tests.api.gpu.geometry;

import haxe.io.Bytes;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using rx.Observable;
using mockatoo.Mockatoo;

class GeometryTests extends BuddySuite
{
    public function new()
    {
        describe('Geometry', {
            
            it('Has a unique identifier for each geometry instance', {
                final g1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final g2 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final g3 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });

                g1.id.should.not.be(g2.id);
                g1.id.should.not.be(g3.id);

                g2.id.should.not.be(g1.id);
                g2.id.should.not.be(g3.id);

                g3.id.should.not.be(g1.id);
                g3.id.should.not.be(g2.id);
            });
            
            it('Has a transformation instance to modify its vertices', {
                final g = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                g.transformation.position.equals(new Vector3()).should.be(true);
                g.transformation.origin.equals(new Vector3()).should.be(true);
                g.transformation.scale.equals(new Vector3(1, 1, 1)).should.be(true);
                g.transformation.rotation.equals(new Quaternion()).should.be(true);
            });

            it('Has shortcut properties to access transformation data', {
                final g = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                g.position.equals(g.transformation.position).should.be(true);
                g.origin.equals(g.transformation.origin).should.be(true);
                g.scale.equals(g.transformation.scale).should.be(true);
                g.rotation.equals(g.transformation.rotation).should.be(true);
            });

            it('Has a clip rectangle for cutting off part of the geometry', {
                final clipRect  = Clip(12, 4, 20, 7);
                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clipRect });

                geometry1.shader.getIndex().should.be(0);
                geometry2.clip.should.equal(clipRect);
            });

            it('Has an array of textures to draw the geometry with', {
                final image = new ImageResource('', 0, 0, Bytes.alloc(0));

                final textures  = Textures([ image ]);
                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), textures : textures });

                geometry1.shader.getIndex().should.be(0);
                geometry2.textures.should.equal(textures);
            });

            it('Has a shader for overriding the batchers shader', {
                final shader    = Shader(mock(ShaderResource));
                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), shader : shader });

                geometry1.shader.getIndex().should.be(0);
                geometry2.shader.should.equal(shader);
            });

            it('Has a uniform for overriding the shaders default', {
                final uniforms  = Uniforms([ mock(UniformBlob) ]);
                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), uniforms : uniforms });
                
                geometry1.uniforms.getIndex().should.be(0);
                geometry2.uniforms.should.equal(uniforms);
            });

            it('Has a depth to decide when it should be drawn', {
                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), depth : 5.2 });
                
                geometry1.depth.should.be(0);
                geometry2.depth.should.be(5.2);
            });

            it('Has a primitive type to tell the renderer how to interpret the vertex data', {
                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), primitive : Points });
                
                geometry1.primitive.should.be(Triangles);
                geometry2.primitive.should.be(Points);
            });

            describe('Changed observable is invoked when a state related property is changed', {
                it('will publish a new onNext event when the depth changes', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.depth = 10;
                    count.should.be(1);

                    geometry.depth = 10;
                    count.should.be(1);
                });
                it('will publish a new onNext event when a shader is assigned', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.shader = Shader(mock(ShaderResource));
                    count.should.be(1);

                    geometry.shader = None;
                    count.should.be(2);
                });
                it('will publish a new onNext event when uniforms are assigned', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.uniforms = Uniforms([ mock(UniformBlob) ]);
                    count.should.be(1);

                    geometry.uniforms = None;
                    count.should.be(2);
                });
                it('will publish a new onNext event when textures are assigned', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.textures = Textures([ new ImageResource('', 0, 0, Bytes.alloc(0)) ]);
                    count.should.be(1);

                    geometry.textures = None;
                    count.should.be(2);
                });
                it('will publish a new onNext event when samplers are assigned', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.samplers = Samplers([ new SamplerState(Border, Border, Linear, Linear) ]);
                    count.should.be(1);

                    geometry.samplers = None;
                    count.should.be(2);
                });
                it('will publish a new onNext event when the clip state is assigned', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.uniforms = Uniforms([ mock(UniformBlob) ]);
                    count.should.be(1);

                    geometry.uniforms = None;
                    count.should.be(2);
                });
                it('will publish a new onNext event when the blend state is assigned', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.blend = new BlendState();
                    count.should.be(1);
                });
                it('will publish a new onNext event when the primitive is changed', {
                    var count = 0;

                    final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    geometry.changed.subscribeFunction(_ -> count++);

                    geometry.primitive = Lines;
                    count.should.be(1);

                    geometry.primitive = Lines;
                    count.should.be(1);
                });
            });
        });
    }
}
