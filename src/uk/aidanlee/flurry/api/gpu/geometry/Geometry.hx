package uk.aidanlee.flurry.api.gpu.geometry;

import signals.Signal1;
import signals.Signal.Signal0;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Transformation;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

using Safety;

typedef GeometryOptions = {
    var ?transform  : Transformation;
    var ?data       : GeometryData;
    var ?shader     : GeometryShader;
    var ?textures   : Array<ImageResource>;
    var ?samplers   : Array<Null<SamplerState>>;
    var ?depth      : Float;
    var ?color      : Color;
    var ?clip       : Rectangle;
    var ?primitive  : PrimitiveType;
    var ?batchers   : Array<Batcher>;
    var ?blend      : Blending;
    var ?uniforms   : Uniforms;
}

enum GeometryData
{
    Indexed(_vertices : VertexBlob, _indices : IndexBlob);
    UnIndexed(_vertices : VertexBlob);
}

enum GeometryShader
{
    None;
    Shader(_shader : ShaderResource);
}

/**
 * The geometry class is the primary way of displaying visuals to the screen.
 * 
 * Geometry contains a collection of vertices which defines the shape of the geometry
 * and other rendering properties which will decide how it is drawn to the screen.
 */
class Geometry
{
    /**
     * Randomly generated ID for this geometry.
     */
    public final id : Int;

    /**
     * Signal which is dispatched when some property of this geometry is changed.
     */
    public final changed : Signal0;

    /**
     * Signal which is dispatched when the geometry is disposed of.
     */
    public final dropped : Signal1<Geometry>;

    /**
     * Transformation of this geometry.
     */
    public final transformation : Transformation;

    /**
     * Default colour of this geometry.
     */
    public final color : Color;

    /**
     * The blend state for this geometry.
     */
    public final blend : Blending;

    /**
     * Clipping rectangle for this geometry. Null if none.
     */
    public final clip : Null<Rectangle>;

    /**
     * All of the images this image will provide to the shader.
     */
    public final textures : Array<ImageResource>;

    /**
     * All of the samplers which will be used to sample data from the corresponding texture.
     */
    public final samplers : Array<Null<SamplerState>>;

    /**
     * Vertex data of this geometry.
     */
    public var data : GeometryData;

    /**
     * The specific shader for the geometry.
     * If null the batchers shader is used.
     */
    public var shader (default, set) : GeometryShader;

    inline function set_shader(_shader : GeometryShader) : GeometryShader {
        shader = _shader;

        changed.dispatch();

        return _shader;
    }

    /**
     * Individual uniform values to override the shaders defaults.
     */
    public var uniforms (default, set) : Null<Uniforms>;

    inline function set_uniforms(_uniforms : Null<Uniforms>) : Null<Uniforms> {
        uniforms = _uniforms;

        changed.dispatch();

        return _uniforms;
    }

    /**
     * The depth of this mesh within the batcher.
     */
    public var depth (default, set) : Float;

    inline function set_depth(_depth : Float) : Float {
        if (depth != _depth)
        {
            depth = _depth;

            changed.dispatch();
        }

        return _depth;
    }

    /**
     * The primitive type of this geometry.
     */
    public var primitive (default, set) : PrimitiveType;

    inline function set_primitive(_primitive : PrimitiveType) : PrimitiveType {
        if (primitive != _primitive)
        {
            primitive = _primitive;

            changed.dispatch();
        }

        return _primitive;
    }

    /**
     * The position of the geometry.
     */
    public var position (get, never) : Vector3;

    inline function get_position() : Vector3 return transformation.position;

    /**
     * The origin of the geometry.
     */
    public var origin (get, never) : Vector3;

    inline function get_origin() : Vector3 return transformation.origin;

    /**
     * Rotation of the geometry.
     */
    public var rotation (get, never) : Quaternion;

    inline function get_rotation() : Quaternion return transformation.rotation;

    /**
     * Scale of the geometry.
     */
    public var scale (get, never) : Vector3;

    inline function get_scale() : Vector3 return transformation.scale;

    /**
     * Create a new mesh, contains no vertices and no transformation.
     */
    public function new(_options : GeometryOptions)
    {
        id = Hash.uniqueHash();

        changed        = new Signal0();
        dropped        = new Signal1<Geometry>();
        data           = _options.data;
        shader         = _options.shader    .or(None);
        transformation = _options.transform .or(new Transformation());
        textures       = _options.textures  .or([]);
        samplers       = _options.samplers  .or([]);
        depth          = _options.depth     .or(0);
        primitive      = _options.primitive .or(Triangles);
        color          = _options.color     .or(new Color());
        blend          = _options.blend     .or(new Blending());
        clip           = _options.clip;
        uniforms       = _options.uniforms;

        // Add to batchers.
        if (_options.batchers != null)
        {
            for (batcher in _options.batchers.unsafe())
            {
                batcher.addGeometry(this);
            }
        }
    }

    /**
     * Remove this geometry from all the batchers it is in.
     */
    public function drop()
    {
        dropped.dispatch(this);

        textures.resize(0);
        samplers.resize(0);

        uniforms = null;
        shader   = null;
    }
}