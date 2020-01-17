package uk.aidanlee.flurry.api.gpu.batcher;

import uk.aidanlee.flurry.api.gpu.state.ClipState;
import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Blending;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

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
    public var shader (default, null) : ShaderResource;

    /**
     * The uniform values currently active in this batcher.
     */
    public var uniforms (default, null) : ReadOnlyArray<UniformBlob>;

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
    public var clip (default, null) : ClipState;

    /**
     * The blend state of the batcher.
     */
    public var blend (default, null) : Blending;

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
        blend        = new Blending();
    }

    /**
     * Returns if batching the provided geometry will require a state change.
     * @param _geom Geometry to be batched.
     * @return Bool
     */
    public function requiresChange(_geom : Geometry) : Bool
    {
        // Check shader ID
        final usedShader = switch _geom.shader
        {
            case None : batcher.shader;
            case Shader(_shader) : _shader;
            case Uniforms(_shader, _) : _shader;
        }
        if (usedShader.id != shader.id) return true;

        // Check uniforms
        final usedUniforms = switch _geom.shader
        {
            case None : [];
            case Shader(_) : [];
            case Uniforms(_, _uniforms) : _uniforms;
        }
        if (usedUniforms.length != uniforms.length) return true;
        for (i in 0...uniforms.length)
        {
            if (uniforms[i] != usedUniforms[i]) return true;
        }

        // Check textures
        if (_geom.textures.length != textures.length) return true;
        for (i in 0...textures.length)
        {
            if (textures[i].id != _geom.textures[i].id) return true;
        }

        // Check samplers
        if (_geom.samplers.length != samplers.length) return true;
        for (i in 0...samplers.length)
        {
            if (samplers[i] == null && _geom.samplers[i] != null) return true;
            if (samplers[i] != null && _geom.samplers[i] == null) return true;
            if (samplers[i] != null && _geom.samplers[i] != null && !samplers[i].equal(_geom.samplers[i])) return true;
        }

        if (_geom.primitive != primitive ) return true;
        if ((_geom.data.getIndex() == 0) != indexed) return true;
        if (!_geom.blend.equals(blend)) return true;

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
            case Shader(_shader) : _shader;
            case Uniforms(_shader, _) : _shader;
        }
        uniforms = switch _geom.shader
        {
            case None : [];
            case Shader(_) : [];
            case Uniforms(_, _uniforms) : _uniforms;
        }

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

        primitive      = _geom.primitive;
        clip           = _geom.clip;
        indexed        = (_geom.data.getIndex() == 0);
        blend.copyFrom(_geom.blend);
    }

    public function drop()
    {
        textures.resize(0);
        samplers.resize(0);
    }
}
