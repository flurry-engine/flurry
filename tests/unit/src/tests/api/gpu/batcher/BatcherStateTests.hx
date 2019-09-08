package tests.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.batcher.BatcherState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Blending;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.maths.Rectangle;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class BatcherStateTests extends BuddySuite
{
    public function new()
    {
        describe('BatcherState', {
            it('Can create a state for a batcher', {
                var state = new BatcherState(mock(Batcher));
                state.textures.should.containExactly([]);
                state.blend.equals(new Blending()).should.be(true);
                state.clip.should.be(null);
            });

            it('Can set its state to that of a geometry', {
                var shader = mock(ShaderResource);
                shader.id.returns('0');

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var clip  = new Rectangle();
                var blend = new Blending();

                var geometry = mock(Geometry);
                geometry.shader.returns(shader);
                geometry.uniforms.returns(uniforms);
                geometry.textures.returns([]);
                geometry.primitive.returns(TriangleStrip);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);

                var state = new BatcherState(batcher);
                state.change(geometry);
                state.shader.should.be(batcher.shader);
                state.uniforms.should.be(uniforms);
                state.textures.should.containExactly(geometry.textures);
                state.primitive.should.equal(geometry.primitive);
                state.clip.equals(clip).should.be(true);
                state.blend.equals(blend).should.be(true);
                state.indexed.should.be(geometry.isIndexed());
            });

            it('Can check if a change is required to batch a default geometry', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('0');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip  = new Rectangle();
                var blend = new Blending();

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);

                var state = new BatcherState(batcher);
                state.requiresChange(geometry).should.be(true);
                state.change(geometry);
                state.requiresChange(geometry).should.be(false);
            });

            it('Will return that the state needs changing when a geometry has a different shader', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader1 = mock(ShaderResource);
                var shader2 = mock(ShaderResource);
                shader1.id.returns('1');
                shader2.id.returns('2');
                shader1.uniforms.returns(uniforms);
                shader2.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader1);

                var clip  = new Rectangle();
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.shader.returns(shader1);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.shader.returns(shader2);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when a geometry has a different number of textures', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip  = new Rectangle();
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.textures.returns([ mock(ImageResource) ]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when a geometry has the same number of textures but different textures', {
                var texture1 = mock(ImageResource);
                var texture2 = mock(ImageResource);
                texture1.id.returns('1');
                texture2.id.returns('2');

                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip  = new Rectangle();
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.textures.returns([ texture1 ]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.textures.returns([ texture2 ]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when the `primitive` properties do not match', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip  = new Rectangle();
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.shader.returns(shader);
                geometry.textures.returns([]);
                geometry.primitive.returns(LineStrip);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when the `isIndexed()` values do not match', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip  = new Rectangle();
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.shader.returns(shader);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(false);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when the clip rectangles do not match', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip1 = new Rectangle(0, 0, 0, 0);
                var clip2 = new Rectangle(1, 2, 3, 4);
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.shader.returns(shader);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip1);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.shader.returns(shader);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip2);
                geometry.blend.returns(blend);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when the blend states do not match', {
                var uniforms = mock(Uniforms);
                uniforms.id.returns(0);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip   = new Rectangle();
                var blend1 = new Blending();
                var blend2 = new Blending(false);
                var state  = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend1);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend2);
                state.requiresChange(geometry).should.be(true);
            });

            it('will return that the state needs changing when the uniforms do not match', {
                var uniforms1 = mock(Uniforms);
                uniforms1.id.returns(0);

                var uniforms2 = mock(Uniforms);
                uniforms2.id.returns(1);

                var shader = mock(ShaderResource);
                shader.id.returns('1');
                shader.uniforms.returns(uniforms1);

                var batcher = mock(Batcher);
                batcher.shader.returns(shader);

                var clip  = new Rectangle();
                var blend = new Blending();
                var state = new BatcherState(batcher);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                state.change(geometry);

                var geometry = mock(Geometry);
                geometry.textures.returns([]);
                geometry.primitive.returns(Triangles);
                geometry.isIndexed().returns(true);
                geometry.clip.returns(clip);
                geometry.blend.returns(blend);
                geometry.uniforms.returns(uniforms2);
                state.requiresChange(geometry).should.be(true);
            });
        });
    }

    function shader(_id : String) : ShaderResource
    {
        return new ShaderResource(_id, new ShaderLayout([], []), null, null, null);
    }
}
