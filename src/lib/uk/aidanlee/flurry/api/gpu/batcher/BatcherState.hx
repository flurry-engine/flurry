package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;

/**
 * Stores all of the state properties for a batcher.
 */
class BatcherState
{
    /**
     * Geometric primitive currently active in this batcher.
     */
    public var primitive (default, null) : PrimitiveType;

    /**
     * The shader currently active in this batcher.
     */
    public var shader (default, null) : ResourceID;

    /**
     * The uniform values currently active in this batcher.
     */
    public var uniforms (default, null) : ReadOnlyArray<UniformBlob>;

    /**
     * The textures currently active in this batcher.
     */
    public var textures (default, null) : ReadOnlyArray<ResourceID>;

    /**
     * The samplers currently active in this batcher.
     */
    public var samplers (default, null) : Array<SamplerState>;

    /**
     * The clipping box currently active in this batcher.
     */
    public var clip (default, null) : ClipState;

    /**
     * The blend state of the batcher.
     */
    public var blend (default, null) : BlendState;

    /**
     * The batcher this state belongs to.
     * Used to set default values for some properties if they're null.
     */
    final batcher : Batcher;

    /**
     * If the current state is for indexed geometry.
     */
    var indexed : Bool;

    /**
     * Creates a batcher state.
     * @param _batcher Batcher this state belongs to.
     */
    public function new(_batcher : Batcher)
    {
        textures     = [];
        samplers     = [];
        uniforms     = [];
        batcher      = _batcher;
        indexed      = false;
        blend        = new BlendState();
    }

    /**
     * Returns if batching the provided geometry will require a state change.
     * @param _geom Geometry to be batched.
     * @return True if a state change is required.
     */
    public function requiresChange(_geom : Geometry) : Bool
    {
        // Check shader ID
        final usedShader = switch _geom.shader
        {
            case None : batcher.shader;
            case Some(_shader) : _shader;
        }
        if (usedShader != shader)
        {
            return true;
        }

        // Check uniforms
        final usedUniforms = switch _geom.uniforms
        {
            case None : [];
            case Some(_uniforms) : _uniforms;
        }
        if (usedUniforms.length != uniforms.length)
        {
            return true;
        }
        for (i in 0...uniforms.length)
        {
            if (uniforms[i].id != usedUniforms[i].id) return true;
        }

        // Check textures
        switch _geom.textures
        {
            case None:
                if (textures.length != 0)
                {
                    return true;
                }
            case Some(_textures):
                if (textures.length != _textures.length)
                {
                    return true;
                }
                for (i in 0...textures.length)
                {
                    if (textures[i] != _textures[i])
                    {
                        return true;
                    }
                }
        }

        // Check samplers
        switch _geom.samplers
        {
            case None:
                if (samplers.length != 0)
                {
                    return true;
                }
            case Some(_samplers):
                if (samplers.length != _samplers.length)
                {
                    return true;
                }
                for (i in 0...samplers.length)
                {
                    if (samplers[i] != _samplers[i])
                    {
                        return true;
                    }
                }
        }

        // Check clip rectangle
        switch _geom.clip
        {
            case None:
                switch clip
                {
                    case None: // no op
                    case Clip(_, _, _, _): return true;
                }
            case Clip(_x1, _y1, _width1, _height1):
                switch clip
                {
                    case None: return true;
                    case Clip(_x2, _y2, _width2, _height2):
                        if (_x1 != _x2 || _y1 != _y2 || _width1 != _width2 || _height1 != _height2)
                        {
                            return true;
                        }
                }
        }

        // Check other small bits.
        if (_geom.primitive != primitive) return true;
        if ((_geom.data.getIndex() == 0) != indexed) return true;
        if (!_geom.blend.equals(blend)) return true;

        return false;
    }

    /**
     * Update this state to work with a geometry instance.
     * @param _geom Geometry.
     */
    public function change(_geom : Geometry)
    {
        shader = switch _geom.shader
        {
            case None : batcher.shader;
            case Some(_shader) : _shader;
        }
        uniforms = switch _geom.uniforms
        {
            case None : [];
            case Some(_uniforms) : _uniforms.copy();
        }
        textures = switch _geom.textures
        {
            case None: [];
            case Some(_textures): _textures.copy();
        }
        samplers = switch _geom.samplers
        {
            case None: [];
            case Some(_samplers): _samplers.copy();
        }

        primitive      = _geom.primitive;
        clip           = _geom.clip;
        indexed        = (_geom.data.getIndex() == 0);
        blend.copyFrom(_geom.blend);
    }

    public function drop()
    {
        textures = [];
        samplers = [];
    }
}
