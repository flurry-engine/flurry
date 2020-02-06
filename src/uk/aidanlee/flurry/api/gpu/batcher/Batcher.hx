package uk.aidanlee.flurry.api.gpu.batcher;

import rx.Unit;
import rx.Subscription;
import rx.disposables.ISubscription;
import haxe.ds.ArraySort;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.maths.Hash;

using Safety;
using rx.Observable;

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
    var ?target : TargetState;

    /**
     * Optional initial depth for this batcher.
     * If not specified the depth starts at 0.
     */
    var ?depth : Float;

    /**
     * Depth testing options to be used by the batcher.
     */
    var ?depthOptions : DepthState;

    /**
     * Stencil testing options to be used by the batcher.
     */
    var ?stencilOptions : StencilState;
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
    public final depthOptions : DepthState;

    /**
     * This batchers stencil testing settings.
     */
    public final stencilOptions : StencilState;

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
    public var target : TargetState;

    /**
     * The state of the batcher.
     */
    final state : BatcherState;

    /**
     * Subscriptions to all of this batchers geometries changed observable.
     */
    final subscriptions : Map<Int, ISubscription>;

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
        subscriptions  = [];
        shader         = _options.shader;
        camera         = _options.camera;
        target         = _options.target.or(Backbuffer);
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
        geometry.push(_geom);
        subscriptions[_geom.id] = _geom.changed.subscribeFunction(setDirty);

        dirty = true;
    }

    /**
     * Remove a geometry from this batcher.
     * @param _geom Geometry to remove.
     */
    public function removeGeometry(_geom : Geometry)
    {
        geometry.remove(_geom);

        subscriptions[_geom.id].unsubscribe();
        subscriptions.remove(_geom.id);

        dirty = true;
    }

    public function batch(_queue : (_geometry : DrawCommand) -> Void)
    {
        // Exit early if there is no geometry to batch.
        if (geometry.length == 0)
        {
            return;
        }

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
            // We make copies of the texture and sampler array as otherwise all commands have the textures and samplers of the last batched geometry.
            if (!batchablePrimitive(geom) || state.requiresChange(geom))
            {
                _queue(new DrawCommand(
                    commandName,
                    commandGeom,
                    camera,
                    state.primitive,
                    state.clip,
                    target,
                    state.shader,
                    state.uniforms,
                    state.textures.copy(),
                    state.samplers.copy(),
                    depthOptions,
                    stencilOptions,
                    state.blend.clone()
                ));

                commandGeom = [];
                commandName = id;

                state.change(geom);
            }

            commandName += geom.id;
            commandGeom.push(geom);
        }

        // Push any remaining verticies.
        if (commandGeom.length > 0)
        {
            _queue(new DrawCommand(
                commandName,
                commandGeom,
                camera,
                state.primitive,
                state.clip,
                target,
                state.shader,
                state.uniforms,
                state.textures.copy(),
                state.samplers.copy(),
                depthOptions,
                stencilOptions,
                state.blend.clone()
            ));
        }
    }

    /**
     * Remove this batcher from the renderer and clear any resources used.
     */
    public function drop()
    {
        state.drop();
        
        geometry.resize(0);
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

        // Sort by shader.
        switch _a.shader
        {
            case None:
                switch _b.shader
                {
                    case None: // no op
                    case _: return -1;
                }
            case Shader(_shaderA):
                switch _b.shader
                {
                    case None: return 1;
                    case Shader(_shaderB):
                        if (_shaderA.id < _shaderB.id) return -1;
                        if (_shaderA.id > _shaderB.id) return  1;
                }
        }

        // Sort by texture.
        switch _a.textures
        {
            case None:
                switch _b.textures
                {
                    case None: // no op
                    case _: return -1;
                }
            case Textures(_texturesA):
                switch _b.textures
                {
                    case None: return 1;
                    case Textures(_texturesB):
                        if (_texturesA[0].id < _texturesB[0].id) return -1;
                        if (_texturesA[0].id > _texturesB[0].id) return  1;
                }
        }

        // Sort by sampler.
        switch _a.samplers
        {
            case None:
                switch _b.samplers
                {
                    case None: // no op
                    case _: return -1;
                }
            case Samplers(_samplersA):
                switch _b.samplers
                {
                    case None: return 1;
                    case Samplers(_samplersB):
                        if (_samplersA[0].equal(_samplersB[0]))
                        {
                            return -1;
                        }
                }
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

    /**
     * Flag the batcher to re-order its geometries.
     */
    function setDirty(_unit : Unit)
    {
        dirty = true;
    }
}
