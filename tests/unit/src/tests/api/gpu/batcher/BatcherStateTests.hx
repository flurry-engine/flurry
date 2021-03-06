package tests.api.gpu.batcher;

import haxe.io.Bytes;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.batcher.BatcherState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.resources.Resource;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class BatcherStateTests extends BuddySuite
{
    public function new()
    {
        describe('BatcherState', {
            it('can detect changes in the geometries primitive type', {
                final batcher = new Batcher({
                    shader: 0,
                    camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                });

                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), primitive : Lines });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), primitive : TriangleStrip });
                final geometry3 = new Geometry({ data : UnIndexed(mock(VertexBlob)), primitive : Points });

                final state = new BatcherState(batcher);
                state.change(geometry1);
                state.requiresChange(geometry1).should.be(false);

                state.requiresChange(geometry2).should.be(true);
                state.change(geometry2);
                state.requiresChange(geometry2).should.be(false);

                state.requiresChange(geometry3).should.be(true);
                state.change(geometry3);
                state.requiresChange(geometry3).should.be(false);
            });

            it('can detect when geometries data changes between indexed and unindexed', {
                final batcher = new Batcher({
                    shader: 0,
                    camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                });

                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : Indexed(mock(VertexBlob), mock(IndexBlob)) });
                final geometry3 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });

                final state = new BatcherState(batcher);
                state.change(geometry1);
                state.requiresChange(geometry1).should.be(false);

                state.requiresChange(geometry2).should.be(true);
                state.change(geometry2);
                state.requiresChange(geometry2).should.be(false);

                state.requiresChange(geometry3).should.be(true);
                state.change(geometry3);
                state.requiresChange(geometry3).should.be(false);
            });

            it('can detect when geometries blend state changes', {
                final blend1 = new BlendState(false, One, Zero, OneMinusDstColor, SrcAlphaSaturate);
                final blend2 = new BlendState(true, One, Zero, OneMinusDstColor, SrcAlphaSaturate);

                final batcher = new Batcher({
                    shader: 0,
                    camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                });

                final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), blend: blend1 });
                final geometry3 = new Geometry({ data : UnIndexed(mock(VertexBlob)), blend: blend2 });

                final state = new BatcherState(batcher);
                state.change(geometry1);
                state.requiresChange(geometry1).should.be(false);

                state.requiresChange(geometry2).should.be(true);
                state.change(geometry2);
                (state.blend == blend1).should.be(true);
                state.requiresChange(geometry2).should.be(false);

                state.requiresChange(geometry3).should.be(true);
                state.change(geometry3);
                (state.blend == blend2).should.be(true);
                state.requiresChange(geometry3).should.be(false);
            });

            describe('shader changing', {
                it('can detect changes when one geometry provides a shader and the other provides none', {
                    final shader1 = 1;
                    final shader2 = 2;
    
                    final batcher = new Batcher({
                        shader: shader1,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), shader : Some(shader2) });
    
                    state.change(geometry1);
                    state.shader.should.be(shader1);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    state.shader.should.be(shader2);
                });
                it('can detect changes when both geometries provide different shaders', {
                    final shader1 = 1;
                    final shader2 = 2;
                    final shader3 = 3;
    
                    final batcher = new Batcher({
                        shader: shader1,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), shader : Some(shader2) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), shader : Some(shader3) });
    
                    state.change(geometry1);
                    state.shader.should.be(shader2);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    state.shader.should.be(shader3);
                });
            });

            describe('uniform changing', {
                it('can detect changes when one geometry provides uniforms and the other provides none', {
                    final uniforms = mock(UniformBlob);
                    final batcher  = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), uniforms : Some([ uniforms ]) });

                    state.change(geometry1);
                    (cast state.uniforms : Array<UniformBlob>).should.containExactly([ ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.uniforms : Array<UniformBlob>).should.containExactly([ uniforms ]);
                });
                it('can detect changes when geometries provide different number of uniforms', {
                    final uniforms = mock(UniformBlob);
                    final batcher  = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), uniforms : Some([ uniforms ]) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), uniforms : Some([ uniforms, uniforms ]) });

                    state.change(geometry1);
                    (cast state.uniforms : Array<UniformBlob>).should.containExactly([ uniforms ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.uniforms : Array<UniformBlob>).should.containExactly([ uniforms, uniforms ]);
                });
                it('can detect changes when geometries provide the same number of uniforms but have different IDs', {
                    final uniforms1 = mock(UniformBlob);
                    uniforms1.id.returns(0);

                    final uniforms2 = mock(UniformBlob);
                    uniforms2.id.returns(1);

                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), uniforms : Some([ uniforms1 ]) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), uniforms : Some([ uniforms2 ]) });

                    state.change(geometry1);
                    (cast state.uniforms : Array<UniformBlob>).should.containExactly([ uniforms1 ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.uniforms : Array<UniformBlob>).should.containExactly([ uniforms2 ]);
                });
            });

            describe('texture changing', {
                it('can detect changes when one geometry provides textures and the other provides none', {
                    final texture = 1;
                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), textures : Some([ texture ]) });

                    state.change(geometry1);
                    (cast state.textures : Array<ResourceID>).should.containExactly([ ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.textures : Array<ResourceID>).should.containExactly([ texture ]);
                });
                it('can detect changes when geometries provide different number of textures', {
                    final texture = 1;
                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), textures : Some([ texture ]) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), textures : Some([ texture, texture ]) });

                    state.change(geometry1);
                    (cast state.textures : Array<ResourceID>).should.containExactly([ texture ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.textures : Array<ResourceID>).should.containExactly([ texture, texture ]);
                });
                it ('can detect changes when geometries provide the same number of textures but are different objects', {
                    final texture1 = 1;
                    final texture2 = 2;
                    final batcher  = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), textures : Some([ 1 ]) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), textures : Some([ 2 ]) });

                    state.change(geometry1);
                    (cast state.textures : Array<ResourceID>).should.containExactly([ texture1 ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.textures : Array<ResourceID>).should.containExactly([ texture2 ]);
                });
            });

            describe('sampler changing', {
                it('can detect changes when one geometry provides samplers and the other provides none', {
                    final sampler = new SamplerState(Border, Border, Linear, Linear);
                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), samplers : Some([ sampler ]) });

                    state.change(geometry1);
                    (cast state.samplers : Array<SamplerState>).should.containExactly([ ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.samplers : Array<SamplerState>).should.containExactly([ sampler ]);
                });
                it('can detect changes when geometries provide different number of samplers', {
                    final sampler = new SamplerState(Border, Border, Linear, Linear);
                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), samplers : Some([ sampler ]) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), samplers : Some([ sampler, sampler ]) });

                    state.change(geometry1);
                    (cast state.samplers : Array<SamplerState>).should.containExactly([ sampler ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.samplers : Array<SamplerState>).should.containExactly([ sampler, sampler ]);
                });
                it('can detect changes when geometries provide the same number of samplers but are different', {
                    final sampler1 = SamplerState.linear;
                    final sampler2 = SamplerState.nearest;
                    final batcher  = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });
    
                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), samplers : Some([ sampler1 ]) });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), samplers : Some([ sampler2 ]) });

                    state.change(geometry1);
                    (cast state.samplers : Array<SamplerState>).should.containExactly([ sampler1 ]);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    (cast state.samplers : Array<SamplerState>).should.containExactly([ sampler2 ]);
                });
            });

            describe('clip changing', {
                it('can detect changes when one geometry procides a clip region and the other doesnt', {
                    final clipNone = ClipState.None;
                    final clipRect = Clip(32, 48, 128, 64);
                    final batcher  = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });

                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clipNone });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clipRect });

                    state.change(geometry1);
                    state.clip.should.equal(clipNone);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    state.clip.should.equal(clipRect);
                });
                it('can detect changes when both geometries provide different clip regions', {
                    final clip1   = Clip(32, 48, 128, 64);
                    final clip2   = Clip(16,  8, 48, 96);
                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });

                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clip1 });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clip2 });

                    state.change(geometry1);
                    state.clip.should.equal(clip1);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(true);
    
                    state.change(geometry2);
                    state.clip.should.equal(clip2);
                });
                it('can detect when both geometries provide clip regions of the same size', {
                    final clip1   = Clip(32, 48, 128, 64);
                    final clip2   = Clip(32, 48, 128, 64);
                    final batcher = new Batcher({
                        shader: 0,
                        camera: new Camera2D(0, 0, TopLeft, ZeroToNegativeOne)
                    });

                    final state     = new BatcherState(batcher);
                    final geometry1 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clip1 });
                    final geometry2 = new Geometry({ data : UnIndexed(mock(VertexBlob)), clip : clip2 });

                    state.change(geometry1);
                    state.clip.should.equal(clip1);
    
                    state.requiresChange(geometry1).should.be(false);
                    state.requiresChange(geometry2).should.be(false);
                });
            });
        });
    }
}
