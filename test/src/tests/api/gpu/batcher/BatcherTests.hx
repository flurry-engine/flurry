package tests.api.gpu.batcher;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class BatcherTests extends BuddySuite
{
    public function new()
    {
        describe('Batcher', {
            it('Has a unique identifier for each batcher', {
                var b1 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                var b2 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                var b3 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });

                b1.id.should.not.be(b2.id);
                b1.id.should.not.be(b3.id);

                b2.id.should.not.be(b1.id);
                b2.id.should.not.be(b3.id);

                b3.id.should.not.be(b1.id);
                b3.id.should.not.be(b2.id);
            });

            it('Has a depth which decides when the batcher contents is drawn', {
                var b1 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                var b2 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource), depth : 3.2 });

                b1.depth.should.be(0);
                b2.depth.should.be(3.2);
            });

            it('Has an array of geometry which it will batch', {
                var g = mock(Geometry);
                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });

                b.geometry.should.containExactly([]);
            });

            it('Has a camera which it will get view and projection matrices from', {
                var c = mock(Camera);
                var b = new Batcher({ camera : c, shader : mock(ShaderResource) });

                b.camera.should.be(c);
            });

            it('Has a shader which it will draw the geometry with', {
                var s = mock(ShaderResource);
                var b = new Batcher({ camera : mock(Camera), shader : s });

                b.shader.should.be(s);
            });

            it('Has a target to allow drawing to a texture', {
                var t = mock(ImageResource);

                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                b.target.should.be(null);

                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource), target : t });
                b.target.should.be(t);
            });

            it('Can be set to dirty to trigger a geometry re-ordering', {
                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                b.isDirty().should.be(false);
                b.setDirty();
                b.isDirty().should.be(true);
            });

            it('Has a function to add geometry and dirty the batcher', {
                var g = mock(Geometry);
                g.batchers.returns([]);

                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                b.addGeometry(g);
                b.isDirty().should.be(true);
            });

            it('Has a function to remove geometry and dirty the batcher', {
                var g = mock(Geometry);
                g.batchers.returns([]);

                var b = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                b.removeGeometry(g);
                b.isDirty().should.be(true);
            });

            describe('Batching', {
                it('Produces geometry draw commands describing how to draw a set of geometry at once', {
                    var uniforms = mock(Uniforms);
                    uniforms.id.returns(0);

                    var shader = mock(ShaderResource);
                    shader.id.returns('1');
                    shader.uniforms.returns(uniforms);

                    var texture = mock(ImageResource);
                    texture.id.returns('1');

                    var camera = mock(Camera);
                    camera.projection.returns(new Matrix());
                    camera.viewInverted.returns(new Matrix());
                    camera.viewport.returns(new Rectangle());

                    var batcher = new Batcher({ shader: shader, camera: mock(Camera) });
                    var geometry1 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData() });
                    var geometry2 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData() });
                    var geometry3 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData() });

                    var commands = batcher.batch();
                    commands.length.should.be(1);

                    commands[0].geometry.length.should.be(3);
                    commands[0].geometry[0].id.should.be(geometry1.id);
                    commands[0].geometry[1].id.should.be(geometry2.id);
                    commands[0].geometry[2].id.should.be(geometry3.id);
                    
                    commands[0].textures.length.should.be(1);
                    commands[0].textures[0].id.should.be(texture.id);

                    commands[0].vertices.should.be(9);
                    commands[0].indices.should.be(0);

                    commands[0].shader.should.not.be(null);
                    commands[0].shader.id.should.be(shader.id);

                    commands[0].target.should.be(null);
                    commands[0].unchanging.should.be(false);
                    commands[0].isIndexed().should.be(false);
                });

                it('Can sort geometry to minimise the number of state changes needed to draw it', {
                    var uniforms = mock(Uniforms);
                    uniforms.id.returns(0);

                    var shader = mock(ShaderResource);
                    shader.id.returns('1');
                    shader.uniforms.returns(uniforms);

                    var texture1 = mock(ImageResource);
                    var texture2 = mock(ImageResource);
                    texture1.id.returns('1');
                    texture2.id.returns('2');

                    var camera = mock(Camera);
                    camera.projection.returns(new Matrix());
                    camera.viewInverted.returns(new Matrix());
                    camera.viewport.returns(new Rectangle());

                    var batcher = new Batcher({ shader: shader, camera: mock(Camera) });
                    var geometry1 = new Geometry({ batchers : [ batcher ], textures : [ texture1 ], vertices : mockVertexData() });
                    var geometry2 = new Geometry({ batchers : [ batcher ], textures : [ texture2 ], vertices : mockVertexData() });
                    var geometry3 = new Geometry({ batchers : [ batcher ], textures : [ texture1 ], vertices : mockVertexData() });

                    var commands = batcher.batch();
                    commands.length.should.be(2);

                    var command = commands[0];
                    command.geometry.length.should.be(2);
                    command.geometry[0].id.should.be(geometry1.id);
                    command.geometry[1].id.should.be(geometry3.id);
                    command.vertices.should.be(6);
                    command.indices.should.be(0);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture1.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.be(null);
                    command.unchanging.should.be(false);
                    command.isIndexed().should.be(false);

                    var command = commands[1];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry2.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture2.id);
                    command.vertices.should.be(3);
                    command.indices.should.be(0);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.be(null);
                    command.unchanging.should.be(false);
                    command.isIndexed().should.be(false);
                });

                it('Produces geometry draw commands which can be flagged as unchanging', {
                    var uniforms = mock(Uniforms);
                    uniforms.id.returns(0);

                    var shader = mock(ShaderResource);
                    shader.id.returns('1');
                    shader.uniforms.returns(uniforms);

                    var texture = mock(ImageResource);
                    texture.id.returns('1');

                    var camera = mock(Camera);
                    camera.projection.returns(new Matrix());
                    camera.viewInverted.returns(new Matrix());
                    camera.viewport.returns(new Rectangle());

                    var batcher = new Batcher({ shader: shader, camera: mock(Camera) });
                    var geometry1 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData() });
                    var geometry2 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData(), unchanging : true });

                    var commands = batcher.batch();
                    commands.length.should.be(2);

                    var command = commands[0];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry1.id);
                    command.vertices.should.be(3);
                    command.indices.should.be(0);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.be(null);
                    command.isIndexed().should.be(false);
                    command.unchanging.should.be(false);

                    var command = commands[1];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry2.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture.id);
                    command.vertices.should.be(3);
                    command.indices.should.be(0);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.be(null);
                    command.isIndexed().should.be(false);
                    command.unchanging.should.be(true);
                });

                it('Produces geometry draw commands which are either indexed or non indexed', {
                    var uniforms = mock(Uniforms);
                    uniforms.id.returns(0);

                    var shader = mock(ShaderResource);
                    shader.id.returns('1');
                    shader.uniforms.returns(uniforms);

                    var texture = mock(ImageResource);
                    texture.id.returns('1');

                    var camera = mock(Camera);
                    camera.projection.returns(new Matrix());
                    camera.viewInverted.returns(new Matrix());
                    camera.viewport.returns(new Rectangle());

                    var batcher = new Batcher({ shader: shader, camera: mock(Camera) });
                    var geometry1 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData() });
                    var geometry2 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData(), indices : mockIndexData() });

                    var commands = batcher.batch();
                    commands.length.should.be(2);

                    var command = commands[0];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry1.id);
                    command.vertices.should.be(3);
                    command.indices.should.be(0);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.be(null);
                    command.unchanging.should.be(false);
                    command.isIndexed().should.be(false);

                    var command = commands[1];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry2.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture.id);
                    command.vertices.should.be(3);
                    command.indices.should.be(6);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.be(null);
                    command.unchanging.should.be(false);
                    command.isIndexed().should.be(true);
                });

                it('Removes immediate geometry from itself once it has been batched', {
                    var uniforms = mock(Uniforms);
                    uniforms.id.returns(0);

                    var shader = mock(ShaderResource);
                    shader.id.returns('1');
                    shader.uniforms.returns(uniforms);

                    var texture = mock(ImageResource);
                    texture.id.returns('1');

                    var camera = mock(Camera);
                    camera.projection.returns(new Matrix());
                    camera.viewInverted.returns(new Matrix());
                    camera.viewport.returns(new Rectangle());

                    var batcher = new Batcher({ shader: shader, camera: mock(Camera) });
                    var geometry1 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData() });
                    var geometry2 = new Geometry({ batchers : [ batcher ], textures : [ texture ], vertices : mockVertexData(), immediate : true });

                    var commands = batcher.batch();
                    commands.length.should.be(1);
                    commands[0].geometry.length.should.be(2);
                    commands[0].geometry[0].id.should.be(geometry1.id);
                    commands[0].geometry[1].id.should.be(geometry2.id);

                    batcher.geometry.length.should.be(1);
                    batcher.geometry[0].id.should.be(geometry1.id);
                });
            });
        });
    }

    private function mockVertexData() : Array<Vertex>
    {
        return [ mock(Vertex), mock(Vertex), mock(Vertex) ];
    }

    private function mockIndexData() : Array<Int>
    {
        return [ 0, 1, 2, 0, 1, 2 ];
    }
}
