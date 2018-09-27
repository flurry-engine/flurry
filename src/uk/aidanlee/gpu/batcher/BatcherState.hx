package uk.aidanlee.gpu.batcher;

import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.resources.Resource.ImageResource;
import snow.api.Debug.def;
import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.gpu.Texture;
import uk.aidanlee.gpu.Shader;
import uk.aidanlee.gpu.geometry.Geometry;

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

        if (_geom.blending  != blending ) return true;
        if (_geom.srcRGB    != srcRGB   ) return true;
        if (_geom.dstRGB    != dstRGB   ) return true;
        if (_geom.srcAlpha  != srcAlpha ) return true;
        if (_geom.dstAlpha  != dstAlpha ) return true;

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

        blending  = _geom.blending;
        srcRGB    = _geom.srcRGB;
        dstRGB    = _geom.dstRGB;
        srcAlpha  = _geom.srcAlpha;
        dstAlpha  = _geom.dstAlpha;
    }
}
