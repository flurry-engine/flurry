package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ArraySort;
import snow.api.Debug.def;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.maths.Hash;

typedef BatcherOptions = {
    var camera : Camera;
    var shader : ShaderResource;
    var ?target : ImageResource;
    var ?depth : Float;
    var ?maxVerts : Int;
}

/**
 * Stores and orders geometry to minimise openGL state changes.
 * 
 * Geometry is stored in this order.
 * - Depth
 * - Texture
 * - Clipping
 * - blend
 */
class Batcher
{
    /**
     * UUID for this batcher.
     */
    public final id : Int;

    /**
     * All of the geometry instances in this batcher.
     */
    public final geometry : Array<Geometry>;

    /**
     * All of the geometry to drop after batching.
     */
    public final geometryToDrop : Array<Geometry>;

    /**
     * The state of the batcher.
     */
    public final state : BatcherState;

    /**
     * Target this batcher will be drawn to.
     * 
     * If null the default target of the renderer will be used (probably the backbuffer).
     */
    public var target : ImageResource;

    /**
     * Camera for this batcher to use.
     */
    public var camera : Camera;

    /**
     * Shader for this batcher to use.
     */
    public var shader : ShaderResource;

    /**
     * The float of this batcher.
     * 
     * The depth of the batcher is the deciding factor in which batchers get drawn first.
     */
    public var depth : Float;

    /**
     * If the batcher needs to sort all of its geometries.
     */
    var dirty : Bool;

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
     * Add a geometry instance into the batcher.
     * @param _geom Geometry to add.
     */
    public function addGeometry(_geom : Geometry)
    {
        geometry.push(_geom);
    }

    /**
     * Removes a geometry instance from the batcher.
     * @param _geom Geometry to move.
     */
    public function removeGeometry(_geom : Geometry)
    {
        geometry.remove(_geom);
    }

    /**
     * Transform and add all the geometry into this batchers buffer.
     * Returns an array of draw commands describing batches within the buffer and the state required to draw them.
     * 
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
                _output.push(new GeometryDrawCommand(commandGeom, commandName, state.unchanging, camera.projection, camera.viewInverted, vertices, camera.viewport, state.primitive, target, state.shader, [ for (texture in state.textures) texture ], state.clip, true, state.blend.srcRGB, state.blend.dstRGB, state.blend.srcAlpha, state.blend.dstAlpha));
                startIndex  = endIndex;
                vertices    = 0;

                commandGeom = new Array<Geometry>();
                commandName = id;

                state.change(geom);
            }

            vertices    += geom.vertices.length;
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
            _output.push(new GeometryDrawCommand(commandGeom, commandName, state.unchanging, camera.projection, camera.viewInverted, vertices, camera.viewport, state.primitive, target, state.shader, [ for (texture in state.textures) texture ], state.clip, true, state.blend.srcRGB, state.blend.dstRGB, state.blend.srcAlpha, state.blend.dstAlpha));
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
