package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Transformation;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;

using Safety;

typedef GeometryOptions = {
    var ?vertices   : Array<Vertex>;
    var ?indices    : Array<Int>;
    var ?transform  : Transformation;
    var ?shader     : ShaderResource;
    var ?textures   : Array<ImageResource>;
    var ?samplers   : Array<Null<SamplerState>>;
    var ?depth      : Float;
    var ?color      : Color;
    var ?clip       : Rectangle;
    var ?primitive  : PrimitiveType;
    var ?batchers   : Array<Batcher>;
    var ?blend      : Blending;
    var ?uniforms   : Uniforms;
    var ?uploadType : UploadType;
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
     * All of the batchers this geometry is in.
     */
    public final batchers : Array<Batcher>;

    /**
     * Transformation of this geometry.
     */
    public final transformation : Transformation;

    /**
     * Vertex data of this geometry.
     */
    public final vertices : Array<Vertex>;

    /**
     * Index data of this geometry.
     * If it is empty then the geometry is drawn unindexed.
     */
    public final indices : Array<Int>;

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
     * Provides a hint to the renderer about how this geometries data should be used.
     */
    public final uploadType : UploadType;

    /**
     * All of the images this image will provide to the shader.
     */
    public final textures : Array<ImageResource>;

    /**
     * All of the samplers which will be used to sample data from the corresponding texture.
     */
    public final samplers : Array<SamplerState>;

    /**
     * The specific shader for the geometry.
     * If null the batchers shader is used.
     */
    public var shader (default, set) : Null<ShaderResource>;

    /**
     * Individual uniform values to override the shaders defaults.
     */
    public var uniforms : Null<Uniforms>;

    inline function set_shader(_shader : Null<ShaderResource>) : Null<ShaderResource> {
        dirtyBatchers();

        return shader = _shader;
    }

    /**
     * The depth of this mesh within the batcher.
     */
    public var depth (default, set) : Float;

    inline function set_depth(_depth : Float) : Float {
        dirtyBatchers();

        return depth = _depth;
    }

    /**
     * The primitive type of this geometry.
     */
    public var primitive (default, set) : PrimitiveType;

    inline function set_primitive(_primitive : PrimitiveType) : PrimitiveType {
        dirtyBatchers();

        return primitive = _primitive;
    }

    /**
     * The position of the geometry.
     */
    public var position (get, never) : Vector;

    inline function get_position() : Vector {
        return transformation.position;
    }

    /**
     * The origin of the geometry.
     */
    public var origin (get, never) : Vector;

    inline function get_origin() : Vector {
        return transformation.origin;
    }

    /**
     * Rotation of the geometry.
     */
    public var rotation (get, never) : Quaternion;

    inline function get_rotation() : Quaternion {
        return transformation.rotation;
    }

    /**
     * Scale of the geometry.
     */
    public var scale (get, never) : Vector;

    inline function get_scale() : Vector {
        return transformation.scale;
    }

    /**
     * Create a new mesh, contains no vertices and no transformation.
     */
    public function new(_options : GeometryOptions)
    {
        id = Hash.uniqueHash();

        batchers       = [];
        uploadType     = _options.uploadType.or(Stream);
        vertices       = _options.vertices  .or([]);
        indices        = _options.indices   .or([]);
        transformation = _options.transform .or(new Transformation());
        textures       = _options.textures  .or([]);
        samplers       = _options.samplers  .or([]);
        depth          = _options.depth     .or(0);
        primitive      = _options.primitive .or(Triangles);
        color          = _options.color     .or(new Color());
        blend          = _options.blend     .or(new Blending());
        clip           = _options.clip;
        shader         = _options.shader;
        uniforms       = _options.uniforms;

        // Add to batchers.
        for (batcher in _options.batchers.or([]))
        {
            batcher.addGeometry(this);
        }
    }

    /**
     * Add a vertex to this mesh.
     * @param _v Vertex to add.
     */
    public function addVertex(_v : Vertex)
    {
        vertices.push(_v);
    }

    /**
     * Remove a vertex from this mesh.
     * @param _v Vertex to remove.
     */
    public function removeVertex(_v : Vertex)
    {
        vertices.remove(_v);
    }

    /**
     * Add a texture to this geometry.
     * Batchers are automatically dirtied.
     * @param _image Image to add.
     */
    public function addTexture(_image : ImageResource)
    {
        textures.push(_image);
        dirtyBatchers();
    }

    /**
     * Remove a texture from this geometry.
     * Batchers are automatically dirtied.
     * @param _image Image to remove.
     */
    public function removeTexture(_image : ImageResource)
    {
        textures.remove(_image);
        dirtyBatchers();
    }

    /**
     * Replace a texture in this geometry.
     * Batchers are automatically dirtied.
     * @param _idx   Texture ID to replace.
     * @param _image Texture to replace with.
     */
    public function setTexture(_idx : Int, _image : ImageResource)
    {
        textures[_idx] = _image;
        dirtyBatchers();
    }

    /**
     * Remove this geometry from all the batchers it is in.
     */
    public function drop()
    {
        for (batcher in batchers)
        {
            batcher.removeGeometry(this);
        }

        batchers.resize(0);
    }

    /**
     * Flags all the batchers this geometry is in for re-ordering.
     */
    public function dirtyBatchers()
    {
        for (batcher in batchers)
        {
            batcher.setDirty();
        }
    }

    /**
     * Convenience function to check if this geometry is indexed.
     */
    public function isIndexed()
    {
        return indices.length != 0;
    }
}
