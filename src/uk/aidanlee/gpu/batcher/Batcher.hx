package uk.aidanlee.gpu.batcher;

import haxe.ds.ArraySort;
import snow.api.buffers.Float32Array;
import snow.api.Debug.def;
import uk.aidanlee.gpu.Shader;
import uk.aidanlee.gpu.camera.Camera;
import uk.aidanlee.gpu.geometry.Geometry;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.utils.Hash;

typedef BatcherOptions = {
    var camera : Camera;
    var shader : Shader;
    @:optional var target : IRenderTarget;
    @:optional var depth : Float;
    @:optional var maxVerts : Int;
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
     * Target this batcher will be drawn to.
     * 
     * If null the default target of the renderer will be used (probably the backbuffer).
     */
    public var target : IRenderTarget;

    /**
     * Camera for this batcher to use.
     */
    public var camera : Camera;

    /**
     * Shader for this batcher to use.
     */
    public var shader : Shader;

    /**
     * All of the geometry instances in this batcher.
     */
    public var geometry : Array<Geometry>;

    /**
     * The state of the batcher.
     */
    public final state : BatcherState;

    /**
     * buffer which the transformed mesh data will be stored in.
     */
    public final vertexBuffer : Float32Array;

    /**
     * The float of this batcher.
     * 
     * The depth of the batcher is the deciding factor in which batchers get drawn first.
     */
    public var depth : Float;

    /**
     * If the geometries need to be re-ordered next time they're batched.
     */
    var orderGeometry : Bool;

    /**
     * Function which sets the orderGeometry flag.
     */
    var onGeometryChanged : EvGeometry->Void;

    /**
     * Creates an empty batcher.
     * @param _options All of the options for this batcher.
     */
    public function new(_options : BatcherOptions)
    {
        id = Hash.uniqueHash();
        
        geometry = [];
        shader   = _options.shader;
        camera   = _options.camera;
        target   = _options.target;
        depth    = def(_options.depth, 0);
        
        vertexBuffer = new Float32Array(def(_options.maxVerts, 10000) * 9);
        state        = new BatcherState(this);

        orderGeometry = true;

        onGeometryChanged = function(_event : EvGeometry) {
            orderGeometry = true;
        }
    }

    /**
     * Add a geometry instance into the batcher.
     * @param _geom Geometry to add.
     */
    inline public function addGeometry(_geom : Geometry)
    {
        geometry.push(_geom);

        _geom.events.on(OrderProperyChanged, onGeometryChanged);

        orderGeometry = true;
    }

    /**
     * Removes a geometry instance from the batcher.
     * @param _geom Geometry to move.
     */
    inline public function removeGeometry(_geom : Geometry)
    {
        geometry.remove(_geom);

        _geom.events.off(OrderProperyChanged, onGeometryChanged);

        orderGeometry = true;
    }

    /**
     * Transform and add all the geometry into this batchers buffer.
     * 
     * Returns an array of draw commands describing batches within the buffer and the state required to draw them.
     * 
     * @return Array<DrawCommand>
     */
    public function batch() : Array<DrawCommand>
    {
        // Exit early if there is no geometry to batch.
        if (geometry.length == 0) return [];

        var startIndex  = 0;
        var endIndex    = 0;
        var vertices    = 0;
        var commands    = new Array<DrawCommand>();
        var commandName = new StringBuf();

        commandName.add(Std.string(id));

        // Sort all of the geometry held in this batcher.
        // Sorted in order of most expensive state changes to least expensive.
        if (orderGeometry)
        {
            ArraySort.sort(geometry, sortGeometry);
            orderGeometry = false;
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
                commands.push(new DrawCommand(Hash.hash(commandName.toString()), state.unchanging, startIndex, endIndex, vertices, camera.projection, camera.viewInverted, camera.viewport, state.primitive, target, state.shader, [ for (texture in state.textures) texture ], state.clip, true, state.srcRGB, state.dstRGB, state.srcAlpha, state.dstAlpha));
                startIndex  = endIndex;
                vertices    = 0;

                commandName = new StringBuf();
                commandName.add(Std.string(id));

                state.change(geom);
            }

            commandName.add(Std.string(geom.id));

            // Transform each vertex in the geometry and add that transformed vertex into our buffer.
            var offset = startIndex + (vertices * 9);
            var transv = new Vector();
            var matrix = geom.transformation.transformation;

            for (vertex in geom.vertices)
            {
                offset = startIndex + (vertices * 9);

                // Copy the vertex into another vertex.
                // This allows us to apply the transformation without permanently modifying the original geometry.
                transv.copyFrom(vertex.position);
                transv.transform(matrix);

                vertexBuffer[offset + 0] = transv.x;
                vertexBuffer[offset + 1] = transv.y;
                vertexBuffer[offset + 2] = transv.z;
                vertexBuffer[offset + 3] = vertex.color.r;
                vertexBuffer[offset + 4] = vertex.color.g;
                vertexBuffer[offset + 5] = vertex.color.b;
                vertexBuffer[offset + 6] = vertex.color.a;
                vertexBuffer[offset + 7] = vertex.texCoord.x;
                vertexBuffer[offset + 8] = vertex.texCoord.y;

                vertices++;
            }

            endIndex += geom.vertices.length * 9;
        }

        // Push any remaining verticies.
        if (vertices > 0)
        {
            commands.push(new DrawCommand(Hash.hash(commandName.toString()), state.unchanging, startIndex, endIndex, vertices, camera.projection, camera.viewInverted, camera.viewport, state.primitive, target, state.shader, [ for (texture in state.textures) texture ], state.clip, true, state.srcRGB, state.dstRGB, state.srcAlpha, state.dstAlpha));
        }

        // Filter out any immediate geometry.
        geometry = geometry.filter(function(_g : Geometry) : Bool {
            return _g.immediate == false;
        });

        return commands;
    }

    /**
     * Returns if the geometry is batchable.
     * 
     * Batchable geometry is of the 'Triangles', 'Lines', or 'Points' geometric primitive.
     * @param _geom Geometry to check.
     */
    function batchablePrimitive(_geom : Geometry) : Bool
    {
        return _geom.primitive == Triangles || _geom.primitive == Lines || _geom.primitive == Points;
    }

    /**
     * Function used to sort the array of geometry.
     * @param _a Geometry a.
     * @param _b Geometry b.
     * @return Int
     */
    function sortGeometry(_a : Geometry, _b : Geometry) : Int
    {
        // Sort by depth.
        if (_a.depth < _b.depth) return -1;
        if (_a.depth > _b.depth) return  1;

        // Sort by texture.
        if (_a.shader != null && _b.shader != null)
        {
            if (_a.shader.shaderID < _b.shader.shaderID) return -1;
            if (_a.shader.shaderID > _b.shader.shaderID) return  1;
        }
        {
            if (_a.shader != null && _b.shader == null) return  1;
            if (_a.shader == null && _b.shader != null) return -1;
        }

        // Sort by texture.
        if (_a.textures.length != 0 && _b.textures.length != 0)
        {
            if (_a.textures[0].textureID < _b.textures[0].textureID) return -1;
            if (_a.textures[0].textureID > _b.textures[0].textureID) return  1;
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
