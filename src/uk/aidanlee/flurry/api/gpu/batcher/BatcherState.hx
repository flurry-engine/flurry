package uk.aidanlee.flurry.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Blending;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

using Safety;

/**
 * Stores all of the state properties for a batcher.
 */
class BatcherState
{
    /**
     * Provides a hint to the backend on how to store the vertex data.
     */
    public var uploadType (default, null) : UploadType;

    /**
     * Geometric primitive currently active in this batcher.
     */
    public var primitive (default, null) : PrimitiveType;

    /**
     * The shader currently active in this batcher.
     */
    public var shader (default, null) : ShaderResource;

    /**
     * The uniform values currently active in this batcher.
     */
    public var uniforms (default, null) : Uniforms;

    /**
     * The textures currently active in this batcher.
     */
    public var textures (default, null) : Array<ImageResource>;

    /**
     * The samplers currently active in this batcher.
     */
    public var samplers (default, null) : Array<Null<SamplerState>>;

    /**
     * The clipping box currently active in this batcher.
     */
    public var clip (default, null) : Null<Rectangle>;

    /**
     * The blend state of the batcher.
     */
    public var blend (default, null) : Blending;

    /**
     * If the current batch is indexed.
     */
    public var indexed (default, null) : Bool;

    /**
     * The batcher this state belongs to.
     * Used to set default values for some properties if they're null.
     */
    final batcher : Batcher;

    /**
     * 
     */
    final internalClip : Rectangle;

    /**
     * Creates a batcher state.
     * @param _batcher Batcher this state belongs to.
     */
    public function new(_batcher : Batcher)
    {
        textures     = [];
        samplers     = [];
        batcher      = _batcher;
        blend        = new Blending();
        internalClip = new Rectangle();
    }

    /**
     * Returns if batching the provided geometry will require a state change.
     * @param _geom Geometry to be batched.
     * @return Bool
     */
    public function requiresChange(_geom : Geometry) : Bool
    {
        if (shader == null)
        {
            return true;
        }

        var usedShader = _geom.shader.or(batcher.shader);

        if (usedShader.id != shader.id) return true;

        if (_geom.uniforms.or(usedShader.uniforms).id != uniforms.id) return true;

        if (_geom.textures.length != textures.length) return true;
        for (i in 0...textures.length)
        {
            if (textures[i].id != _geom.textures[i].id) return true;
        }

        if (_geom.samplers.length != samplers.length) return true;
        for (i in 0...samplers.length)
        {
            if (samplers[i] == null && _geom.samplers[i] != null) return true;
            if (samplers[i] != null && _geom.samplers[i] == null) return true;
            if (samplers[i] != null && _geom.samplers[i] != null && !samplers[i].equal(_geom.samplers[i])) return true;
        }

        if (_geom.uploadType  != uploadType) return true;
        if (_geom.primitive   != primitive ) return true;
        if (_geom.isIndexed() != indexed   ) return true;
        if (!_geom.blend.equals(blend)) return true;

        if (_geom.clip == null && clip != null) return true;
        if (_geom.clip != null && clip == null) return true;
        if (_geom.clip != null && clip != null && !_geom.clip.equals(clip)) return true;

        return false;
    }

    /**
     * Update this state to work with a geometry instance.
     * @param _geom Geometry.
     */
    public function change(_geom : Geometry)
    {
        var usedShader = _geom.shader.or(batcher.shader);

        shader   = usedShader;
        uniforms = _geom.uniforms.or(usedShader.uniforms);

        if (_geom.textures.length != textures.length)
        {
            textures.resize(_geom.textures.length);
        }
        for (i in 0...textures.length)
        {
            textures[i] = _geom.textures[i];
        }

        if (_geom.samplers.length != samplers.length)
        {
            samplers.resize(_geom.samplers.length);
        }
        for (i in 0...samplers.length)
        {
            samplers[i] = _geom.samplers[i];
        }

        uploadType = _geom.uploadType;
        primitive  = _geom.primitive;
        indexed    = _geom.isIndexed();
        blend.copyFrom(_geom.blend);

        if (clip == null)
        {
            if (_geom.clip != null)
            {
                clip = internalClip;
                clip.copyFrom(_geom.clip);
            }
        }
        else
        {
            if (_geom.clip != null)
            {
                clip.copyFrom(_geom.clip);
            }
            else
            {
                clip = null;
            }
        }
    }

    public function drop()
    {
        textures.resize(0);
        samplers.resize(0);
    }
}
