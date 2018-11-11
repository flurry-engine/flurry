package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ArraySort;
import snow.api.Debug.def;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.maths.Hash;

typedef BatcherOptions = {
    /**
     * The initial camera this batcher will use.
     */
    var camera : Camera;

    /**
     * The initial shader this batcher will use.
     */
    var shader : ShaderResource;

    /**
     * Optional render target for this batcher.
     * If not specified the backbuffer / default target will be used.
     */
    var ?target : ImageResource;

    /**
     * Optional initial depth for this batcher.
     * If not specified the depth starts at 0.
     */
    var ?depth : Float;
}

/**
 * A batcher is used to sort a set of geometries so that the renderer can draw them
 * as effeciently as possible while retaining the user requested depth ordering.
 * 
 * Batchers must contain a camera and a shader. The attached camera is used to provided
 * the shader with a view matrix to transform all the geometry by the inverse of the cameras
 * position.
 * 
 * The batcher generates a set of draw commands which are then fed to the renderer for uploading
 * and drawing. The geometry instances call the setDirty() function to flag the batcher to
 * re-order all the contained geometry.
 */
class Batcher
{
    /**
     * Randomly generated ID for this batcher.
     */
    public final id : Int;

    /**
     * The depth of the batcher is the deciding factor in which batchers get drawn first.
     */
    public var depth : Float;

    /**
     * All of the geometry in this batcher.
     */
    public final geometry : Array<Geometry>;

    /**
     * Camera for this batcher to use.
     */
    public var camera : Camera;

    /**
     * Shader for this batcher to use.
     */
    public var shader : ShaderResource;

    /**
     * Target this batcher will be drawn to.
     * 
     * If null the backbuffer / default target will be used.
     */
    public var target : ImageResource;

    /**
     * If the batcher needs to sort all of its geometries.
     */
    var dirty : Bool;

    /**
     * All of the geometry to remove after batching.
     */
    final geometryToDrop : Array<Geometry>;

    /**
     * The state of the batcher.
     */
    final state : BatcherState;

    /**
     * Creates an empty batcher.
     * @param _options All of the options for this batcher.
     */
    public function new(_options : BatcherOptions)
    {
        id = Hash.uniqueHash();
        
        geometry       = [];
        geometryToDrop = [];
        shader   = _options.shader;
        camera   = _options.camera;
        target   = _options.target;
        depth    = def(_options.depth, 0);

        state = new BatcherState(this);
        dirty = true;
    }

    /**
     * Flag the batcher to re-order its geometries.
     */
    public function setDirty()
    {
        dirty = true;
    }

    /**
     * Add a geometry to this batcher.
     * @param _geom Geometry to add.
     */
    public function addGeometry(_geom : Geometry)
    {
        _geom.batchers.push(this);

        geometry.push(_geom);

        dirty = true;
    }

    /**
     * Remove a geometry from this batcher.
     * @param _geom Geometry to remove.
     */
    public function removeGeometry(_geom : Geometry)
    {
        _geom.batchers.remove(this);

        geometry.remove(_geom);

        dirty = true;
    }

    /**
     * Generates a series of geometry draw commands from the geometry in this batcher.
     * @param _output Optional existing array to put all the draw commands in.
     * @return Array<GeometryDrawCommand>
     */
    public function batch(_output : Array<GeometryDrawCommand> = null) : Array<GeometryDrawCommand>
    {
        // Clear the array of geometry to drop.
        geometryToDrop.resize(0);

        // If we are not provided an array, create a new one which we will return.
        if (_output == null)
        {
            _output = [];
        }

        // Exit early if there is no geometry to batch.
        if (geometry.length == 0)
        {
            return _output;
        }

        var startIndex  = 0;
        var endIndex    = 0;
        var vertices    = 0;
        var indices     = 0;
        var commandGeom = [];
        var commandName = id;

        // Sort all of the geometry held in this batcher.
        // Sorted in order of most expensive state changes to least expensive.
        if (dirty)
        {
            ArraySort.sort(geometry, sortGeometry);
            dirty = false;
        }

        // Set the intial state to the first bit of geometry.
        // This prevents a state change when checking the very first bit of geometry in the iteration.
        state.change(geometry[0]);

        for (geom in geometry)
        {
            // Only triangles, lines, and points can be batched.
            // Line lists and triangle lists cannot (yet).
            if (!batchablePrimitive(geom) || state.requiresChange(geom))
            {
                _output.push(new GeometryDrawCommand(commandGeom, commandName, state.unchanging, camera.projection, camera.viewInverted, vertices, indices, camera.viewport, state.primitive, target, state.shader, [ for (texture in state.textures) texture ], state.clip, true, state.blend.srcRGB, state.blend.dstRGB, state.blend.srcAlpha, state.blend.dstAlpha));
                startIndex  = endIndex;
                vertices    = 0;
                indices     = 0;

                commandGeom = new Array<Geometry>();
                commandName = id;

                state.change(geom);
            }

            vertices    += geom.vertices.length;
            indices     += geom.indices.length;
            commandName += geom.id;
            commandGeom.push(geom);

            if (geom.immediate)
            {
                geometryToDrop.push(geom);
            }
        }

        // Push any remaining verticies.
        if (vertices > 0)
        {
            _output.push(new GeometryDrawCommand(commandGeom, commandName, state.unchanging, camera.projection, camera.viewInverted, vertices, indices, camera.viewport, state.primitive, target, state.shader, [ for (texture in state.textures) texture ], state.clip, true, state.blend.srcRGB, state.blend.dstRGB, state.blend.srcAlpha, state.blend.dstAlpha));
        }

        // Filter out any immediate geometry.
        for (geom in geometryToDrop)
        {
            geometry.remove(geom);
        }

        return _output;
    }

    /**
     * Returns if the geometry is batchable.
     * 
     * Batchable geometry is of the 'Triangles', 'Lines', or 'Points' geometric primitive.
     * @param _geom Geometry to check.
     */
    inline function batchablePrimitive(_geom : Geometry) : Bool
    {
        return _geom.primitive == Triangles || _geom.primitive == Lines || _geom.primitive == Points;
    }

    /**
     * Function used to sort the array of geometry.
     * @param _a Geometry a.
     * @param _b Geometry b.
     * @return Int
     */
    inline function sortGeometry(_a : Geometry, _b : Geometry) : Int
    {
        // Sort by depth.
        if (_a.depth < _b.depth) return -1;
        if (_a.depth > _b.depth) return  1;

        // Sort by texture.
        if (_a.shader != null && _b.shader != null)
        {
            if (_a.shader.id < _b.shader.id) return -1;
            if (_a.shader.id > _b.shader.id) return  1;
        }
        {
            if (_a.shader != null && _b.shader == null) return  1;
            if (_a.shader == null && _b.shader != null) return -1;
        }

        // Sort by texture.
        if (_a.textures.length != 0 && _b.textures.length != 0)
        {
            if (_a.textures[0].id < _b.textures[0].id) return -1;
            if (_a.textures[0].id > _b.textures[0].id) return  1;
        }
        {
            if (_a.textures.length != 0 && _b.textures.length == 0) return  1;
            if (_a.textures.length == 0 && _b.textures.length != 0) return -1;
        }

        // Sort by primitive.
        var aPrimitiveIndex = _a.primitive.getIndex();
        var bPrimitiveIndex = _b.primitive.getIndex();

        if (aPrimitiveIndex < bPrimitiveIndex) return -1;
        if (aPrimitiveIndex > bPrimitiveIndex) return  1;

        // Sort by clip.
        if (_a.clip != _b.clip)
        {
            if (_a.clip == null && _b.clip != null) return  1;
            if (_a.clip != null && _b.clip == null) return -1;
        }

        return 0;
    }
}
