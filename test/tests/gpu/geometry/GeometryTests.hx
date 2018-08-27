package tests.gpu.geometry;

import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.gpu.Texture;
import uk.aidanlee.gpu.Shader;
import uk.aidanlee.gpu.batcher.Batcher;
import uk.aidanlee.gpu.geometry.Vertex;
import uk.aidanlee.gpu.geometry.Geometry;
import uk.aidanlee.gpu.geometry.Color;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;

class GeometryTests extends BuddySuite
{
    public function new()
    {
        describe('Geometry', {
            var geomDefault : Geometry;
            var geomCustom  : Geometry;
            var shdr = mock(Shader);
            var txtr = mock(Texture);

            beforeEach({
                geomDefault = new Geometry({});
                geomCustom  = new Geometry({
                    name       : 'custom name',
                    shader     : shdr,
                    textures   : [ txtr ],
                    clip       : new Rectangle(32, 64, 128, 256),
                    depth      : 2,
                    immediate  : true,
                    unchanging : true,
                    primitive  : Lines,
                    color      : new Color(0.25, 0.5, 0.3),

                    blending   : false,
                    srcRGB     : OneMinusSrcAlpha,
                    srcAlpha   : One,
                    dstRGB     : DstAlpha,
                    dstAlpha   : SrcAlphaSaturate,
                });
            });

            it('Can create geometry with default settings', {
                geomDefault.name.should.be('');
                geomDefault.shader.should.be(null);
                geomDefault.textures.should.containExactly([ ]);
                geomDefault.clip.should.be(null);
                geomDefault.depth.should.be(0);
                geomDefault.immediate.should.be(false);
                geomDefault.unchanging.should.be(false);
                geomDefault.primitive.should.equal(Triangles);
                geomDefault.color.r.should.be(1);
                geomDefault.color.g.should.be(1);
                geomDefault.color.b.should.be(1);
                geomDefault.color.a.should.be(1);
                geomDefault.blending.should.be(true);
                geomDefault.srcRGB.should.equal(SrcAlpha);
                geomDefault.srcAlpha.should.equal(One);
                geomDefault.dstRGB.should.equal(OneMinusSrcAlpha);
                geomDefault.dstAlpha.should.equal(Zero);
            });

            it('Can create geometry with custom settings', {
                geomCustom.name.should.be('custom name');
                geomCustom.shader.should.be(shdr);
                geomCustom.textures.should.containExactly([ txtr ]);
                geomCustom.clip.x.should.be(32);
                geomCustom.clip.y.should.be(64);
                geomCustom.clip.w.should.be(128);
                geomCustom.clip.h.should.be(256);
                geomCustom.depth.should.be(2);
                geomCustom.immediate.should.be(true);
                geomCustom.unchanging.should.be(true);
                geomCustom.primitive.should.equal(Lines);
                geomCustom.color.r.should.be(0.25);
                geomCustom.color.g.should.be(0.5);
                geomCustom.color.b.should.be(0.3);
                geomCustom.color.a.should.be(1);
                geomCustom.blending.should.be(false);
                geomCustom.srcRGB.should.equal(OneMinusSrcAlpha);
                geomCustom.srcAlpha.should.equal(One);
                geomCustom.dstRGB.should.equal(DstAlpha);
                geomCustom.dstAlpha.should.equal(SrcAlphaSaturate);
            });

            it('Can add vertices to the geoemtry', {
                var v1 = new Vertex(null, null, null);
                var v2 = new Vertex(null, null, null);
                var v3 = new Vertex(null, null, null);

                geomDefault.addVertex(v1);
                geomDefault.addVertex(v2);
                geomDefault.addVertex(v3);
                geomDefault.vertices.should.containExactly([ v1, v2, v3 ]);
            });

            it('Can remove vertices from the geoemtry', {
                var v1 = new Vertex(null, null, null);
                var v2 = new Vertex(null, null, null);
                var v3 = new Vertex(null, null, null);

                geomDefault.addVertex(v1);
                geomDefault.addVertex(v2);
                geomDefault.addVertex(v3);

                geomDefault.removeVertex(v2);
                geomDefault.vertices.should.containExactly([ v1, v3 ]);
            });

            it ('Can set the transformation position of the geometry', {
                var pos = new Vector(32, 64, 96);
                geomDefault.setPosition(pos);

                geomDefault.transformation.position.x.should.be(32);
                geomDefault.transformation.position.y.should.be(64);
                geomDefault.transformation.position.z.should.be(96);
            });

            it ('Can set the transformation scale of the geometry', {
                var scl = new Vector(0.2, 3.4, 1.0);
                geomDefault.setScale(scl);

                geomDefault.transformation.scale.x.should.be(0.2);
                geomDefault.transformation.scale.y.should.be(3.4);
                geomDefault.transformation.scale.z.should.be(1.0);
            });

            describe('Geometries have an events emitter which can be listened to', {
                it ('Fires an OrderProperyChanged event when the depth is changed', {
                    var callCount = 0;
                    var onChanged = function(_event : EvGeometry) {
                        callCount++;
                    };

                    geomDefault.events.on(OrderProperyChanged, onChanged);
                    geomDefault.depth = 7;

                    callCount.should.be(1);
                });

                it ('Fires an OrderProperyChanged event when the clip is changed', {
                    var callCount = 0;
                    var onChanged = function(_event : EvGeometry) {
                        callCount++;
                    };

                    geomDefault.events.on(OrderProperyChanged, onChanged);
                    geomDefault.clip = new Rectangle();

                    callCount.should.be(1);
                });

                it ('Fires an OrderProperyChanged event when the shader is changed', {
                    var callCount = 0;
                    var onChanged = function(_event : EvGeometry) {
                        callCount++;
                    };

                    geomDefault.events.on(OrderProperyChanged, onChanged);
                    geomDefault.shader = null;

                    callCount.should.be(1);
                });

                it ('Fires an OrderProperyChanged event when the primitive is changed', {
                    var callCount = 0;
                    var onChanged = function(_event : EvGeometry) {
                        callCount++;
                    };

                    geomDefault.events.on(OrderProperyChanged, onChanged);
                    geomDefault.primitive = Triangles;

                    callCount.should.be(1);
                });
            });
        });
    }
}
