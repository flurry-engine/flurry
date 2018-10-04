package tests.gpu.batcher;

import uk.aidanlee.maths.Vector;
import uk.aidanlee.maths.Maths;
import uk.aidanlee.gpu.geometry.Geometry;
import uk.aidanlee.gpu.geometry.Vertex;
import uk.aidanlee.gpu.geometry.Color;
import uk.aidanlee.gpu.batcher.Batcher;
import uk.aidanlee.gpu.camera.Camera;
import uk.aidanlee.utils.Hash;
import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.resources.Resource.ImageResource;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class BatcherTests extends BuddySuite
{
    public function new()
    {
        describe('Batcher', {
            it('Can add geometry into the batcher', {
                var batcher = new Batcher({
                    camera : mock(Camera),
                    shader : mock(ShaderResource)
                });

                batcher.addGeometry(new Geometry({}));
                batcher.addGeometry(new Geometry({}));

                batcher.geometry.length.should.be(2);
            });
            it('Can remove geometry from the batcher', {
                var batcher = new Batcher({
                    camera : mock(Camera),
                    shader : mock(ShaderResource)
                });

                var g1 = new Geometry({});
                var g2 = new Geometry({});

                batcher.addGeometry(g1);
                batcher.addGeometry(g2);
                batcher.geometry.length.should.be(2);

                batcher.removeGeometry(g1);
                batcher.geometry.length.should.be(1);
            });

            describe('Batching', {
                it('It can sort geometry to reduce the number of state changes', {
                    // Mock some textures.
                    var texture1 = mock(ImageResource);
                    var texture2 = mock(ImageResource);
                    texture1.id.returns('test_image_1');
                    texture2.id.returns('test_image_2');

                    // Mock some geometry and get them to return depth and texture values.
                    var geometry1 = createGeometry1();
                    var geometry2 = createGeometry2();
                    var geometry3 = createGeometry3();
                    geometry1.depth = 1;
                    geometry2.depth = 1;
                    geometry3.depth = 1;
                    geometry1.textures.push(texture1);
                    geometry2.textures.push(texture2);
                    geometry3.textures.push(texture1);

                    var batcher = new Batcher({
                        camera : mock(Camera),
                        shader : mock(ShaderResource)
                    });

                    batcher.addGeometry(geometry1);
                    batcher.addGeometry(geometry2);
                    batcher.addGeometry(geometry3);
                    batcher.batch();

                    batcher.geometry.should.containExactly([ geometry1, geometry3, geometry2 ]);
                });
                it('Produces an array of geometry draw commands describing how to draw the contained geometry', {
                    // Mock some textures.
                    var texture1 = mock(ImageResource);
                    var texture2 = mock(ImageResource);
                    texture1.id.returns('test_image_1');
                    texture2.id.returns('test_image_2');

                    // Mock some geometry and get them to return depth and texture values.
                    var geometry1 = createGeometry1();
                    var geometry2 = createGeometry2();
                    var geometry3 = createGeometry3();
                    geometry1.depth = 1;
                    geometry2.depth = 1;
                    geometry3.depth = 1;
                    geometry1.textures.push(texture1);
                    geometry2.textures.push(texture2);
                    geometry3.textures.push(texture1);

                    var batcher = new Batcher({
                        camera : mock(Camera),
                        shader : mock(ShaderResource)
                    });

                    batcher.addGeometry(geometry1);
                    batcher.addGeometry(geometry2);
                    batcher.addGeometry(geometry3);
                    var commands = batcher.batch();

                    commands.length.should.be(2);

                    commands[0].vertices.should.be(12);
                    commands[0].geometry.length.should.be(2);
                    commands[0].geometry[0].should.be(geometry1);
                    commands[0].geometry[1].should.be(geometry3);

                    commands[1].vertices.should.be(6);
                    commands[1].geometry.length.should.be(1);
                    commands[1].geometry[0].should.be(geometry2);
                });
                it('Produces draw commands which are either unchanging or dynamic', {
                    // Mock some textures.
                    var texture1 = mock(ImageResource);
                    texture1.id.returns('test_image_1');

                    // Mock some geometry and get them to return depth and texture values.
                    var geometry1 = createGeometry1();
                    var geometry2 = createGeometry2();
                    var geometry3 = createGeometry3();
                    geometry1.depth = 1;
                    geometry2.depth = 1;
                    geometry3.depth = 1;
                    geometry1.textures.push(texture1);
                    geometry2.textures.push(texture1);
                    geometry3.textures.push(texture1);

                    geometry2.unchanging = true;

                    var batcher = new Batcher({
                        camera : mock(Camera),
                        shader : mock(ShaderResource)
                    });

                    batcher.addGeometry(geometry1);
                    batcher.addGeometry(geometry2);
                    batcher.addGeometry(geometry3);
                    var commands = batcher.batch();

                    commands[0].unchanging.should.be(false);
                    commands[1].unchanging.should.not.be(false);
                });
                it('Transforms its geometries vertices and places them in a buffer', {
                    // Mock some textures.
                    var texture1 = mock(ImageResource);
                    var texture2 = mock(ImageResource);
                    texture1.id.returns('test_image_1');
                    texture2.id.returns('test_image_2');

                    // Mock some geometry and get them to return depth and texture values.
                    var geometry1 = createGeometry1();
                    var geometry2 = createGeometry2();
                    var geometry3 = createGeometry3();
                    geometry1.depth = 1;
                    geometry2.depth = 1;
                    geometry3.depth = 1;
                    geometry1.textures.push(texture1);
                    geometry2.textures.push(texture2);
                    geometry3.textures.push(texture1);

                    var batcher = new Batcher({
                        camera : mock(Camera),
                        shader : mock(ShaderResource)
                    });

                    batcher.addGeometry(geometry1);
                    batcher.addGeometry(geometry2);
                    batcher.addGeometry(geometry3);
                    
                    var transVector = new Vector();
                    var commands    = batcher.batch();

                    // Command 0 contains geometry 1 and 3.
                    // Command 1 contains geometry 2.
                    // Check all 6 vertices of the 3 geometries to ensure they have been transformed correctly and inserted into the buffer.
                    /*
                    for (i in 0...6)
                    {
                        // Check geometry 1s vertex.
                        var vertex = geometry1.vertices[i];
                        var start  = commands[0].bufferStartIndex + (i * 9);

                        transVector.copyFrom(vertex.position).transform(geometry1.transformation.transformation);
                        batcher.vertexBuffer[start + 0].should.beCloseTo(transVector.x, 4);
                        batcher.vertexBuffer[start + 1].should.beCloseTo(transVector.y, 4);
                        batcher.vertexBuffer[start + 2].should.beCloseTo(transVector.z, 4);

                        // Check geometry 2s vertex.
                        var vertex = geometry2.vertices[i];
                        var start  = commands[1].bufferStartIndex + (i * 9);

                        transVector.copyFrom(vertex.position).transform(geometry2.transformation.transformation);
                        batcher.vertexBuffer[start + 0].should.beCloseTo(transVector.x, 4);
                        batcher.vertexBuffer[start + 1].should.beCloseTo(transVector.y, 4);
                        batcher.vertexBuffer[start + 2].should.beCloseTo(transVector.z, 4);

                        // Check geometry 3s vertex.
                        var vertex = geometry3.vertices[i];
                        var start  = commands[0].bufferStartIndex + (6 * 9) + (i * 9);

                        transVector.copyFrom(vertex.position).transform(geometry3.transformation.transformation);
                        batcher.vertexBuffer[start + 0].should.beCloseTo(transVector.x, 4);
                        batcher.vertexBuffer[start + 1].should.beCloseTo(transVector.y, 4);
                        batcher.vertexBuffer[start + 2].should.beCloseTo(transVector.z, 4);
                    }
                    */
                });
                it('Immediate geometry is dropped after being batched', {
                    // Mock some textures.
                    var texture1 = mock(ImageResource);
                    var texture2 = mock(ImageResource);
                    texture1.id.returns('test_image_1');
                    texture2.id.returns('test_image_2');

                    // Mock some geometry and get them to return depth and texture values.
                    var geometry1 = createGeometry1();
                    var geometry2 = createGeometry2();
                    var geometry3 = createGeometry3();
                    var geometry4 = createImmediateGeometry();
                    geometry1.depth = 1;
                    geometry2.depth = 1;
                    geometry3.depth = 1;
                    geometry4.depth = 1;
                    geometry1.textures.push(texture1);
                    geometry2.textures.push(texture2);
                    geometry3.textures.push(texture1);
                    geometry4.textures.push(texture2);

                    var batcher = new Batcher({
                        camera : mock(Camera),
                        shader : mock(ShaderResource)
                    });

                    batcher.addGeometry(geometry1);
                    batcher.addGeometry(geometry2);
                    batcher.addGeometry(geometry4);
                    batcher.addGeometry(geometry3);

                    // First batch, immediate geometry will be included.
                    var commands = batcher.batch();

                    commands.length.should.be(2);

                    //commands[0].bufferStartIndex.should.be(0);
                    //commands[0].bufferEndIndex.should.be(108);
                    commands[0].vertices.should.be(12);

                    //commands[1].bufferStartIndex.should.be(108);
                    //commands[1].bufferEndIndex.should.be(216);
                    commands[1].vertices.should.be(12);

                    // Second batch, immediate geometry will have been dropped.
                    var commands = batcher.batch();

                    commands.length.should.be(2);

                    //commands[0].bufferStartIndex.should.be(0);
                    //commands[0].bufferEndIndex.should.be(108);
                    commands[0].vertices.should.be(12);

                    //commands[1].bufferStartIndex.should.be(108);
                    //commands[1].bufferEndIndex.should.be(162);
                    commands[1].vertices.should.be(6);
                });
            });
        });
    }

    inline function createGeometry1() : Geometry
    {
        var mesh = new Geometry({ name : 'geom1' });

        mesh.transformation.origin.set_xy(32, 32);
        mesh.transformation.position.set_xy(32, 32);
        mesh.transformation.scale.set_xy(2, 2);
        mesh.transformation.rotation.setFromAxisAngle(new Vector(0, 0, 1), Maths.toRadians(45));

        mesh.addVertex(new Vertex( new Vector( 0, 64), new Color(), new Vector(0, 1) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));

        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector(64,  0), new Color(), new Vector(1, 0) ));

        return mesh;
    }

    inline function createGeometry2() : Geometry
    {
        var mesh = new Geometry({ name : 'geom2' });

        mesh.transformation.position.set_xy(512, 256);
        mesh.transformation.scale.set_xy(2, 2);

        mesh.addVertex(new Vertex( new Vector( 0, 64), new Color(), new Vector(0, 1) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));

        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector(64,  0), new Color(), new Vector(1, 0) ));

        return mesh;
    }

    inline function createGeometry3() : Geometry
    {
        var mesh = new Geometry({});

        mesh.transformation.position.set_xy(64, 32);
        mesh.transformation.scale.set_xy(4, 4);

        mesh.addVertex(new Vertex( new Vector( 0, 64), new Color(), new Vector(0, 1) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));

        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector(64,  0), new Color(), new Vector(1, 0) ));

        return mesh;
    }

    inline function createImmediateGeometry() : Geometry
    {
        var mesh = new Geometry({ immediate : true });

        mesh.transformation.position.set_xy(256, 128);
        mesh.transformation.scale.set_xy(2, 2);

        mesh.addVertex(new Vertex( new Vector( 0, 64), new Color(), new Vector(0, 1) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));

        mesh.addVertex(new Vertex( new Vector( 0,  0), new Color(), new Vector(0, 0) ));
        mesh.addVertex(new Vertex( new Vector(64, 64), new Color(), new Vector(1, 1) ));
        mesh.addVertex(new Vertex( new Vector(64,  0), new Color(), new Vector(1, 0) ));

        return mesh;
    }
}
