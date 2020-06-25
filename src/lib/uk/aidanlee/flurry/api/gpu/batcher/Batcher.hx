package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.ArraySort;
import rx.Unit;
import rx.disposables.ISubscription;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

using rx.Observable;

/**
 * Batchers sort geometry to preserve the visual order and reduce the amount of work the renderer backends need to do.
 */
class Batcher
{
    /**
     * All of the geometry in this batcher.
     */
    public final geometry : Array<Geometry>;

    /**
     * This batchers depth testing settings.
     */
    public var depthOptions : DepthState;

    /**
     * This batchers stencil testing settings.
     */
    public var stencilOptions : StencilState;

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
        geometry       = [];
        subscriptions  = [];
        shader         = _options.shader;
        camera         = _options.camera;
        target         = _options.target;
        depth          = _options.depth;
        depthOptions   = _options.depthOptions;
        stencilOptions = _options.stencilOptions;

        state = new BatcherState(this);
        dirty = false;
    }

    /**
     * Add a geometry to this batcher.
     * This causes the batcher to sort all geometry for the next drawn frame.
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
     * This causes the batcher to sort all geometry for the next drawn frame.
     * @param _geom Geometry to remove.
     */
    public function removeGeometry(_geom : Geometry)
    {
        geometry.remove(_geom);

        subscriptions[_geom.id].unsubscribe();
        subscriptions.remove(_geom.id);

        dirty = true;
    }

    /**
     * Generate a series of draw commands to optimally draw the contained geometry.
     * @param _queue The function draw commands are sent to.
     */
    public function batch(_queue : (_geometry : DrawCommand) -> Void)
    {
        // Exit early if there is no geometry to batch.
        if (geometry.length == 0)
        {
            return;
        }

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

                state.change(geom);
            }

            commandGeom.push(geom);
        }

        // Push any remaining verticies.
        if (commandGeom.length > 0)
        {
            _queue(new DrawCommand(
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
     * Removes all geometry in this batcher.
     */
    public function drop()
    {
        state.drop();
        
        for (geom in geometry)
        {
            subscriptions[geom.id].unsubscribe();
            subscriptions.remove(geom.id);
        }

        geometry.resize(0);

        dirty = true;
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

        // sort by uniforms
        switch _a.uniforms
        {
            case None:
                switch _b.uniforms
                {
                    case None: // no op
                    case Uniforms(_): return -1;
                }
            case Uniforms(_uniformsA):
                switch _b.uniforms
                {
                    case None: return 1;
                    case Uniforms(_uniformsB):
                        if (_uniformsA.length == _uniformsB.length)
                        {
                            for (i in 0..._uniformsA.length)
                            {
                                if (_uniformsA[i].id < _uniformsB[i].id) return -1;
                                if (_uniformsA[i].id > _uniformsB[i].id) return  1;
                            }
                        }
                        else
                        {
                            return _uniformsA.length - _uniformsB.length;
                        }
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
                        if (_texturesA.length == _texturesB.length)
                        {
                            for (i in 0..._texturesA.length)
                            {
                                if (_texturesA[i].id < _texturesB[i].id) return -1;
                                if (_texturesA[i].id > _texturesB[i].id) return  1;
                            }
                        }
                        else
                        {
                            return _texturesA.length - _texturesB.length;
                        }
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
                        if (_samplersA.length == _samplersB.length)
                        {
                            for (i in 0..._samplersA.length)
                            {
                                if (!_samplersA[i].equal(_samplersB[i]))
                                {
                                    return -1;
                                }
                            }
                        }
                        else
                        {
                            return _samplersA.length - _samplersB.length;
                        }
                }
        }

        // Sort by clip.
        switch _a.clip
        {
            case None:
                switch _b.clip
                {
                    case None: // no op
                    case Clip(_, _, _, _): return -1;
                }
            case Clip(_x1, _y1, _width1, _height1):
                switch _b.clip
                {
                    case None: return 1;
                    case Clip(_x2, _y2, _width2, _height2):
                        if (_x1 != _x2 || _y1 != _y2 || _width1 != _width2 || _height1 != _height2)
                        {
                            return -1;
                        }
                }
        }

        // Sort by blend
        if (!_a.blend.equals(_b.blend))
        {
            return -1;
        }

        // Sort by primitive.
        if ((cast _a.primitive : Int) < (cast _b.primitive : Int)) return -1;
        if ((cast _a.primitive : Int) > (cast _b.primitive : Int)) return  1;

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

@:structInit class BatcherOptions
{
    /**
     * The camera this batcher will use.
     */
    public final camera : Camera;

    /**
     * The shader this batcher will use.
     */
    public final shader : ShaderResource;

    /**
     * Optional render target for this batcher.
     * If not specified the backbuffer will be used.
     */
    public final target : TargetState = Backbuffer;

    /**
     * Optional initial depth for this batcher.
     * If not specified the depth starts at 0.
     */
    public final depth = 0.0;

    /**
     * Depth testing options to be used by the batcher.
     */
    public final depthOptions : DepthState = {
        depthTesting  : false,
        depthMasking  : false,
        depthFunction : Always
    };

    /**
     * Stencil testing options to be used by the batcher.
     */
    public final stencilOptions : StencilState = {
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
    };
}
