package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.ds.Option;
import haxe.ds.ReadOnlyArray;
import rx.Unit;
import rx.Subject;
import rx.observables.IObservable;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Transformation;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;

using Safety;

enum GeometryData
{
    Indexed(_vertices : VertexBlob, _indices : IndexBlob);
    UnIndexed(_vertices : VertexBlob);
}

typedef GeometryShader = Option<ResourceID>;

typedef GeometryUniforms = Option<ReadOnlyArray<UniformBlob>>;

typedef GeometryTextures = Option<ReadOnlyArray<ResourceID>>;

typedef GeometrySamplers = Option<ReadOnlyArray<SamplerState>>;

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
    public final changed : IObservable<Unit>;

    /**
     * Vertex data of this geometry.
     */
    public var data : GeometryData;

    /**
     * Transformation of this geometry.
     */
    public var transformation : Transformation;

    /**
     * The depth of this mesh within the batcher.
     */
    public var depth (default, set) = 0.0;

    inline function set_depth(_depth : Float) : Float {
        if (depth != _depth)
        {
            depth = _depth;

            (cast changed : Subject<Unit>).onNext(unit);
        }

        return _depth;
    }

    /**
     * The specific shader for the geometry.
     * If null the batchers shader is used.
     */
    public var shader (default, set) : GeometryShader;

    inline function set_shader(_shader : GeometryShader) : GeometryShader {
        shader = _shader;

        (cast changed : Subject<Unit>).onNext(unit);

        return _shader;
    }

    /**
     * The uniform data provided to the vertex and fragment shader when drawing this geometry.
     */
    public var uniforms (default, set) : GeometryUniforms;

    inline function set_uniforms(_uniforms : GeometryUniforms) : GeometryUniforms {
        uniforms = _uniforms;

        (cast changed : Subject<Unit>).onNext(unit);

        return _uniforms;
    }

    /**
     * All of the textures this geometry will provide to the shader.
     */
    public var textures (default, set) : GeometryTextures;

    inline function set_textures(_textures : GeometryTextures) : GeometryTextures {
        textures = _textures;

        (cast changed : Subject<Unit>).onNext(unit);

        return _textures;
    }

    /**
     * All of the samplers this geometry will provide to the shader.
     * If none (and textures are provided), or less than the number of textures are provided then a default sampler is used.
     */
    public var samplers (default, set) : GeometrySamplers;

    inline function set_samplers(_samplers : GeometrySamplers) : GeometrySamplers {
        samplers = _samplers;

        (cast changed : Subject<Unit>).onNext(unit);

        return _samplers;
    }

    /**
     * Clipping rectangle for this geometry. Null if none.
     */
    public var clip (default, set) : ClipState;

    inline function set_clip(_clip : ClipState) : ClipState {
        clip = _clip;

        (cast changed : Subject<Unit>).onNext(unit);

        return _clip;
    }

    /**
     * The blend state for this geometry.
     */
    public var blend (default, set) : BlendState;

    inline function set_blend(_blend : BlendState) : BlendState
    {
        blend = _blend;

        (cast changed : Subject<Unit>).onNext(unit);

        return _blend;
    }

    /**
     * The primitive type of this geometry.
     */
    public var primitive (default, set) = PrimitiveType.Triangles;

    inline function set_primitive(_primitive : PrimitiveType) : PrimitiveType {
        if (primitive != _primitive)
        {
            primitive = _primitive;

            (cast changed : Subject<Unit>).onNext(unit);
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
        id      = Hash.uniqueHash();
        changed = new Subject<Unit>();

        data           = _options.data;
        transformation = _options.transform;
        depth          = _options.depth;
        shader         = _options.shader;
        uniforms       = _options.uniforms;
        textures       = _options.textures;
        samplers       = _options.samplers;
        clip           = _options.clip;
        blend          = _options.blend;
        primitive      = _options.primitive;

        if (_options.batchers != null)
        {
            for (batcher in _options.batchers)
            {
                batcher.addGeometry(this);
            }
        }
    }
}

@:structInit class GeometryOptions
{
    /**
     * Vertex and optionally index data of this geometry.
     */
    public final data : GeometryData;

    /**
     * Specify an existing transformation to be used by this geometry.
     * If none is provided a new transformation is created.
     */
    public final transform = new Transformation();

    /**
     * Initial depth of the geometry.
     * If none is provided 0 is used.
     */
    public final depth = 0.0;

    /**
     * Specify a custom shader to be used by this geometry.
     * If none is provided the batchers shader is used.
     */
    public final shader = GeometryShader.None;

    /**
     * Specify custom uniform blocks to be passed to the shader.
     * If none is provided the batchers uniforms are used.
     */
    public final uniforms = GeometryUniforms.None;

    /**
     * Any textures to be used by this geometry.
     */
    public final textures = GeometryTextures.None;

    /**
     * Any samplers to be used by this geometry.
     * If textures are specified by an equal number of samplers are not a default sampler is used.
     * Default samplers is clamp uv clipping and nearest neighbour scaling.
     */
    public final samplers = GeometrySamplers.None;

    /**
     * Custom clip rectangle for this geometry.
     * Defaults to clipping based on the batchers camera.
     */
    public final clip = ClipState.None;

    /**
     * Provides custom blending operations for drawing this geometry.
     */
    public final blend = BlendState.none;

    /**
     * The primitive to draw this geometries vertex data with.
     */
    public final primitive = PrimitiveType.Triangles;

    /**
     * The batchers to initially add this geometry to.
     */
    public final batchers = new Array<Batcher>();
}