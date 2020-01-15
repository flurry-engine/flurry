package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ArraySort;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.maths.Hash;

using Safety;

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

    /**
     * Depth testing options to be used by the batcher.
     */
    var ?depthOptions : DepthOptions;

    /**
     * Stencil testing options to be used by the batcher.
     */
    var ?stencilOptions : StencilOptions;
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
     * All of the geometry in this batcher.
     */
    public final geometry : Array<Geometry>;

    /**
     * This batchers depth testing settings.
     */
    public final depthOptions : DepthOptions;

    /**
     * This batchers stencil testing settings.
     */
    public final stencilOptions : StencilOptions;

    /**
     * The depth of the batcher is the deciding factor in which batchers get drawn first.
     */
    public var depth : Float;

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
        shader         = _options.shader;
        camera         = _options.camera;
        target         = _options.target;
        depth          = _options.depth.or(0);
        depthOptions   = _options.depthOptions.or({
            depthTesting  : false,
            depthMasking  : false,
            depthFunction : Always
        });
        stencilOptions = _options.stencilOptions.or({
            stencilTesting : false,

            stencilFrontMask          : 0xff,
            stencilFrontFunction      : Always,
            stencilFrontTestFail      : Keep,
            stencilFrontDepthTestFail : Keep,
            stencilFrontDepthTestPass : Keep,
            
            stencilBackMask          : 0xff,
            stencilBackFunction      : Always,
            stencilBackTestFail      : Keep,
            stencilBackDepthTestFail : Keep,
            stencilBackDepthTestPass : Keep
        });

        state = new BatcherState(this);
        dirty = false;
    }

    /**
     * Flag the batcher to re-order its geometries.
     */
    public function setDirty()
    {
        dirty = true;
    }

    /**
     * Returns if this batcher is currently flagged as dirty.
     * @return Bool
     */
    public function isDirty() : Bool
    {
        return dirty;
    }

    /**
     * Add a geometry to this batcher.
     * @param _geom Geometry to add.
     */
    public function addGeometry(_geom : Geometry)
    {
        _geom.changed.add(setDirty);
        _geom.dropped.add(removeGeometry);

        geometry.push(_geom);

        dirty = true;
    }

    /**
     * Remove a geometry from this batcher.
     * @param _geom Geometry to remove.
     */
    public function removeGeometry(_geom : Geometry)
    {
        _geom.changed.remove(setDirty);
        _geom.dropped.remove(removeGeometry);

        geometry.remove(_geom);

        dirty = true;
    }

    public function batch(_queue : (_geometry : GeometryDrawCommand) -> Void)
    {
        // Clear the array of geometry to drop.
        geometryToDrop.resize(0);

        // Exit early if there is no geometry to batch.
        if (geometry.length == 0)
        {
            return;
        }

        var startIndex  = 0;
        var endIndex    = 0;
        var commandName = 0;
        var commandGeom = [];

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
                _queue(new GeometryDrawCommand(
                    commandGeom,
                    commandName,
                    state.uploadType,
                    camera,
                    state.clip,
                    state.primitive,
                    target,
                    state.shader,
                    state.uniforms,
                    [ for (texture in state.textures) texture ],
                    [ for (i in 0...state.textures.length) i >= state.samplers.length ? null : state.samplers[i] ],
                    depthOptions,
                    stencilOptions,
                    true,
                    state.blend.srcRGB,
                    state.blend.dstRGB,
                    state.blend.srcAlpha,
                    state.blend.dstAlpha
                ));
                startIndex  = endIndex;

                commandGeom = [];
                commandName = id;

                state.change(geom);
            }

            commandName += geom.id;
            commandGeom.push(geom);

            if (geom.uploadType == Immediate)
            {
                geometryToDrop.push(geom);
            }
        }

        // Push any remaining verticies.
        if (commandGeom.length > 0)
        {
            _queue(new GeometryDrawCommand(
                commandGeom,
                commandName,
                state.uploadType,
                camera,
                state.clip,
                state.primitive,
                target,
                state.shader,
                state.uniforms,
                [ for (texture in state.textures) texture ],
                [ for (i in 0...state.textures.length) i >= state.samplers.length ? null : state.samplers[i] ],
                depthOptions,
                stencilOptions,
                true,
                state.blend.srcRGB,
                state.blend.dstRGB,
                state.blend.srcAlpha,
                state.blend.dstAlpha
            ));
        }

        // Filter out any immediate geometry.
        for (geom in geometryToDrop)
        {
            removeGeometry(geom);
        }
    }

    /**
     * Remove this batcher from the renderer and clear any resources used.
     */
    public function drop()
    {
        state.drop();
        
        geometry.resize(0);
        geometryToDrop.resize(0);
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
        else
        {
            if (_a.textures.length != 0 && _b.textures.length == 0) return  1;
            if (_a.textures.length == 0 && _b.textures.length != 0) return -1;
        }

        // Sort by primitive.
        if ((cast _a.primitive : Int) < (cast _b.primitive : Int)) return -1;
        if ((cast _a.primitive : Int) > (cast _b.primitive : Int)) return  1;

        // Sort by clip.
        if (_a.clip != _b.clip)
        {
            if (_a.clip == null && _b.clip != null) return  1;
            if (_a.clip != null && _b.clip == null) return -1;
        }

        return 0;
    }
}
