package uk.aidanlee.flurry.api.gpu.geometry;

import rx.Subject;
import rx.Unit;
import rx.Observable;
import haxe.ds.ReadOnlyArray;
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
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

using Safety;

typedef GeometryOptions = {
    var ?transform  : Transformation;
    var ?data       : GeometryData;
    var ?shader     : GeometryShader;
    var ?uniforms   : GeometryUniforms;
    var ?textures   : GeometryTextures;
    var ?samplers   : GeometrySamplers;
    var ?depth      : Float;
    var ?clip       : ClipState;
    var ?primitive  : PrimitiveType;
    var ?batchers   : Array<Batcher>;
    var ?blend      : BlendState;
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

enum GeometryUniforms
{
    None;
    Uniforms(_uniforms : ReadOnlyArray<UniformBlob>);
}

enum GeometryTextures
{
    None;
    Textures(_textures : ReadOnlyArray<ImageResource>);
}

enum GeometrySamplers
{
    None;
    Samplers(_samplers : ReadOnlyArray<SamplerState>);
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
    public final changed : Observable<Unit>;

    /**
     * Transformation of this geometry.
     */
    public final transformation : Transformation;

    /**
     * The blend state for this geometry.
     */
    public final blend : BlendState;

    /**
     * Clipping rectangle for this geometry. Null if none.
     */
    public final clip : ClipState;

    /**
     * Vertex data of this geometry.
     */
    public var data : GeometryData;

    /**
     * All of the images this image will provide to the shader.
     */
    public var textures (default, set) : GeometryTextures;

    inline function set_textures(_textures : GeometryTextures) : GeometryTextures {
        textures = _textures;

        (cast changed : Subject<Unit>).onNext(unit);

        return _textures;
    }

    public var samplers (default, set) : GeometrySamplers;

    inline function set_samplers(_samplers : GeometrySamplers) : GeometrySamplers {
        samplers = _samplers;

        (cast changed : Subject<Unit>).onNext(unit);

        return _samplers;
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

    public var uniforms (default, set) : GeometryUniforms;

    inline function set_uniforms(_uniforms : GeometryUniforms) : GeometryUniforms {
        uniforms = _uniforms;

        (cast changed : Subject<Unit>).onNext(unit);

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

            (cast changed : Subject<Unit>).onNext(unit);
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
        id = Hash.uniqueHash();

        changed        = Subject.create();
        data           = _options.data;
        shader         = _options.shader    .or(None);
        uniforms       = _options.uniforms  .or(None);
        textures       = _options.textures  .or(None);
        samplers       = _options.samplers  .or(None);
        clip           = _options.clip      .or(None);
        primitive      = _options.primitive .or(Triangles);
        depth          = _options.depth     .or(0);
        transformation = _options.transform .or(new Transformation());
        blend          = _options.blend     .or(new BlendState());

        // Add to batchers.
        if (_options.batchers != null)
        {
            for (batcher in _options.batchers.unsafe())
            {
                batcher.addGeometry(this);
            }
        }
    }
}