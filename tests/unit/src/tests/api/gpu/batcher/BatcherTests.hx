package tests.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
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
            it('Has a depth which decides when the batcher contents is drawn', {
                final batcher1 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                final batcher2 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource), depth : 3.2 });

                batcher1.depth.should.be(0);
                batcher2.depth.should.be(3.2);
            });

            it('Has an array of geometry which it will batch', {
                final batcher = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });

                batcher.geometry.should.containExactly([]);
            });

            it('Has a camera which it will get view and projection matrices from', {
                final camera  = mock(Camera);
                final batcher = new Batcher({ camera : camera, shader : mock(ShaderResource) });

                batcher.camera.should.be(camera);
            });

            it('Has a shader which it will draw the geometry with', {
                final shader  = mock(ShaderResource);
                final batcher = new Batcher({ camera : mock(Camera), shader : shader });

                batcher.shader.should.be(shader);
            });

            it('Has a target to allow drawing to a texture', {
                final target   = Texture(mock(ImageResource));
                final batcher1 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                final batcher2 = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource), target : target });

                batcher1.target.should.equal(Backbuffer);
                batcher2.target.should.equal(target);
            });

            it('Has a function to add geometry and dirty the batcher', {
                final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final batcher  = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                batcher.addGeometry(geometry);

                batcher.geometry.should.contain(geometry);
            });

            it('Has a function to remove geometry and dirty the batcher', {
                final geometry = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final batcher  = new Batcher({ camera : mock(Camera), shader : mock(ShaderResource) });
                batcher.addGeometry(geometry);
                batcher.removeGeometry(geometry);

                batcher.geometry.should.not.contain(geometry);
            });

            describe('Batching', {
                it('Produces geometry draw commands describing how to draw a set of geometry at once', {
                    final shader = mock(ShaderResource);
                    shader.id.returns('1');

                    final texture = mock(ImageResource);
                    texture.id.returns('1');

                    final batcher   = new Batcher({ shader: shader, camera: mock(Camera) });
                    final geometry1 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture ]), data : unindexedData() });
                    final geometry2 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture ]), data : unindexedData() });
                    final geometry3 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture ]), data : unindexedData() });

                    final commands = [];
                    batcher.batch(cmd -> commands.push(cmd));
                    commands.length.should.be(1);

                    commands[0].geometry.length.should.be(3);
                    commands[0].geometry[0].id.should.be(geometry1.id);
                    commands[0].geometry[1].id.should.be(geometry2.id);
                    commands[0].geometry[2].id.should.be(geometry3.id);
                    
                    commands[0].textures.length.should.be(1);
                    commands[0].textures[0].id.should.be(texture.id);

                    commands[0].shader.should.not.be(null);
                    commands[0].shader.id.should.be(shader.id);

                    commands[0].target.should.equal(Backbuffer);
                });

                it('Can sort geometry to minimise the number of state changes needed to draw it', {
                    final shader = mock(ShaderResource);
                    shader.id.returns('1');

                    final texture1 = mock(ImageResource);
                    final texture2 = mock(ImageResource);
                    texture1.id.returns('1');
                    texture2.id.returns('2');

                    final batcher   = new Batcher({ shader: shader, camera: mock(Camera) });
                    final geometry1 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture1 ]), data : unindexedData() });
                    final geometry2 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture2 ]), data : unindexedData() });
                    final geometry3 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture1 ]), data : unindexedData() });

                    final commands = [];
                    batcher.batch(cmd -> commands.push(cmd));
                    commands.length.should.be(2);

                    final command = commands[0];
                    command.geometry.length.should.be(2);
                    command.geometry[0].id.should.be(geometry1.id);
                    command.geometry[1].id.should.be(geometry3.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture1.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.equal(Backbuffer);

                    final command = commands[1];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry2.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture2.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.equal(Backbuffer);
                });
                
                it('Produces geometry draw commands which are either indexed or non indexed', {
                    final shader = mock(ShaderResource);
                    shader.id.returns('1');

                    final texture = mock(ImageResource);
                    texture.id.returns('1');

                    final batcher   = new Batcher({ shader: shader, camera: mock(Camera) });
                    final geometry1 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture ]), data : unindexedData() });
                    final geometry2 = new Geometry({ batchers : [ batcher ], textures : Textures([ texture ]), data : indexedData() });

                    final commands = [];
                    batcher.batch(cmd -> commands.push(cmd));
                    commands.length.should.be(2);

                    final command = commands[0];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry1.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.equal(Backbuffer);

                    final command = commands[1];
                    command.geometry.length.should.be(1);
                    command.geometry[0].id.should.be(geometry2.id);
                    command.textures.length.should.be(1);
                    command.textures[0].id.should.be(texture.id);
                    command.shader.should.not.be(null);
                    command.shader.id.should.be(shader.id);
                    command.target.should.equal(Backbuffer);
                });
            });
        });
    }

    function unindexedData() : GeometryData
    {
        return UnIndexed(
            new VertexBlobBuilder()
                .addFloat3(0, 0, 0).addFloat4(1, 1, 1, 1).addFloat2(0, 0)
                .vertexBlob());
    }

    function indexedData() : GeometryData
    {
        return Indexed(
            new VertexBlobBuilder()
                .addFloat3(0, 0, 0).addFloat4(1, 1, 1, 1).addFloat2(0, 0)
                .vertexBlob(),
            new IndexBlobBuilder()
                .addInt(0)
                .indexBlob());
    }
}
