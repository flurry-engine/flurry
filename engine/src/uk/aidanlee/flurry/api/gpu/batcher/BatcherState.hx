package uk.aidanlee.flurry.api.gpu.batcher;

import snow.api.Debug.def;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

/**
 * 
 */
class BatcherState
{
    /**
     * The batcher this state belongs to.
     * Used to set default values for some properties if they're null.
     */
    final batcher : Batcher;

    /**
     * If the current state is unchanging.
     */
    public var unchanging (default, null) : Bool;

    /**
     * Geometric primitive currently active in this batcher.
     */
    public var primitive (default, null) : PrimitiveType;

    /**
     * The shader currently active in this batcher.
     */
    public var shader (default, null) : ShaderResource;

    /**
     * The textures currently active in this batcher.
     */
    public var textures (default, null) : Array<ImageResource>;

    /**
     * The clipping box currently active in this batcher.
     */
    public var clip (default, null) : Rectangle;

    public var blending (default, null) : Bool;

    public var srcRGB (default, null) : BlendMode;

    public var dstRGB (default, null) : BlendMode;

    public var srcAlpha (default, null) : BlendMode;

    public var dstAlpha (default, null) : BlendMode;

    /**
     * Creates a batcher state.
     * @param _batcher Batcher this state belongs to.
     */
    inline public function new(_batcher : Batcher)
    {
        textures = [];
        batcher  = _batcher;
    }

    /**
     * Returns if batching the provided geometry will require a state change.
     * @param _geom Geometry to be batched.
     * @return Bool
     */
    public function requiresChange(_geom : Geometry) : Bool
    {
        if (def(_geom.shader, batcher.shader) != shader ) return true;

        if (_geom.textures.length != textures.length) return true;
        for (i in 0...textures.length)
        {
            if (textures[i].id != _geom.textures[i].id) return true;
        }

        if (_geom.unchanging != unchanging) return true;
        if (_geom.primitive  != primitive ) return true;
        if (_geom.clip       != clip      ) return true;

        if (_geom.blend.enabled  != blending ) return true;
        if (_geom.blend.srcRGB   != srcRGB   ) return true;
        if (_geom.blend.dstRGB   != dstRGB   ) return true;
        if (_geom.blend.srcAlpha != srcAlpha ) return true;
        if (_geom.blend.dstAlpha != dstAlpha ) return true;

        return false;
    }

    /**
     * Update this state to work with a geometry instance.
     * @param _geom Geometry.
     */
    inline public function change(_geom : Geometry)
    {
        shader = def(_geom.shader, batcher.shader);

        if (_geom.textures.length != textures.length)
        {
            textures.resize(_geom.textures.length);
        }
        for (i in 0...textures.length)
        {
            textures[i] = _geom.textures[i];
        }

        unchanging = _geom.unchanging;
        primitive  = _geom.primitive;
        clip       = _geom.clip;

        blending  = _geom.blend.enabled;
        srcRGB    = _geom.blend.srcRGB;
        dstRGB    = _geom.blend.dstRGB;
        srcAlpha  = _geom.blend.srcAlpha;
        dstAlpha  = _geom.blend.dstAlpha;
    }
}
