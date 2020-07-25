package uk.aidanlee.flurry.api.gpu.batcher;

import haxe.ds.List;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher.BatcherOptions;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob.IndexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;

using Safety;

class Painter implements IBatchable
{
    final queue : List<DrawCommand>;

    final target : TargetState;
    
    final camera : Camera;

    final depth : Float;

    final depthState : DepthState;

    final stencilState : StencilState;

    final colours : List<Vector4>;

    final samplers : List<SamplerState>;

    final shaders : List<ResourceID>;

    var vtxCount : Int;

    var vtxBuffer : VertexBlobBuilder;

    var idxBuffer : IndexBlobBuilder;

    var texture : ResourceID;

    var primitive : PrimitiveType;

    public function new(_options : BatcherOptions)
    {
        queue        = new List();
        camera       = _options.camera;
        target       = _options.target;
        depth        = _options.depth;
        depthState   = _options.depthOptions;
        stencilState = _options.stencilOptions;
        colours      = new List();
        shaders      = new List();
        samplers     = new List();
        texture      = 0;
        primitive    = Triangles;

        colours.push(new Vector4(1, 1, 1, 1));
        shaders.push(_options.shader);
        samplers.push(SamplerState.nearest);
    }

    public function getDepth() return depth;

    public function getTarget() return target;

    public function getShader() return shaders.last().unsafe();

    public function batch(_queue : (_geometry : DrawCommand) -> Void)
    {
        while (queue.length > 0)
        {
            _queue(queue.pop().unsafe());
        }
    }

    public function pushColour(_colour : Vector4)
    {
        colours.push(_colour);
    }

    public function popColour()
    {
        colours.pop();
    }

    public function pushShader(_shader : ResourceID)
    {
        if (requireFlush(texture, _shader, primitive, samplers.first()))
        {
            flush(texture, shaders.first(), primitive, samplers.first());
        }

        shaders.push(_shader);
    }

    public function popShader()
    {
        if (shaders.length > 1)
        {
            final removed = shaders.pop();

            if (requireFlush(texture, removed, primitive, samplers.first()))
            {
                flush(texture, removed, primitive, samplers.first());
            }
        }
    }

    /**
     * Update the sampler used by this painter.
     * If it is different from the current active sampler it will flush the contents.
     * @param _sampler Sampler to use.
     */
    public function pushSampler(_sampler : SamplerState)
    {
        if (requireFlush(texture, shaders.first(), primitive, _sampler))
        {
            flush(texture, shaders.first(), primitive, samplers.first());
        }

        samplers.push(_sampler);
    }

    /**
     * Removes the sampler at the top of the stack.
     * If the next sampler on the stack is not equal to the one remove, the contents will be flushed.
     */
    public function popSampler()
    {
        if (samplers.length > 1)
        {
            final removed = samplers.pop();

            if (requireFlush(texture, shaders.first(), primitive, removed))
            {
                flush(texture, shaders.first(), primitive, removed);
            }
        }
    }

    public function begin()
    {
        reset();
    }

    public function drawRectangle(_x : Float, _y : Float, _width : Float, _height : Float)
    {
        flush(texture, shaders.first(), primitive, samplers.first());

        primitive = LineStrip;

        final colour = colours.first();

        vtxBuffer
            .addFloat3(_x         , _y          , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x + _width, _y          , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x + _width, _y + _height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x         , _y + _height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x         , _y          , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0);
        idxBuffer
            .addInt(vtxCount + 0).addInt(vtxCount + 1).addInt(vtxCount + 2).addInt(vtxCount + 3).addInt(vtxCount + 4);

        vtxCount += 4;
    }

    public function drawRectangleFilled(_x : Float, _y : Float, _width : Float, _height : Float)
    {
        if (requireFlush(texture, shaders.first(), Triangles, samplers.first()))
        {
            flush(texture, shaders.first(), primitive, samplers.first());

            primitive = Triangles;
        }

        final colour = colours.first();

        vtxBuffer
            .addFloat3(_x         , _y + _height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x + _width, _y + _height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x         , _y          , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x + _width, _y          , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0);
        idxBuffer
            .addInt(vtxCount + 0).addInt(vtxCount + 1).addInt(vtxCount + 2).addInt(vtxCount + 2).addInt(vtxCount + 1).addInt(vtxCount + 3);

        vtxCount += 4;
    }

    public function drawLine(_x1 : Float, _y1 : Float, _x2 : Float, _y2 : Float)
    {
        if (requireFlush(texture, shaders.first(), Lines, samplers.first()))
        {
            flush(texture, shaders.first(), primitive, samplers.first());

            primitive = Lines;
        }

        final colour = colours.first();

        vtxBuffer
            .addFloat3(_x1, _y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0)
            .addFloat3(_x2, _y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(0, 0);
        idxBuffer
            .addInt(vtxCount + 0).addInt(vtxCount + 1);

        vtxCount += 2;
    }

    public function drawFrame(_frame : ImageFrameResource, _x : Float, _y : Float)
    {
        if (requireFlush(_frame.image, shaders.first(), Triangles, samplers.first()))
        {
            flush(texture, shaders.first(), primitive, samplers.first());

            texture   = _frame.image;
            primitive = Triangles;
        }

        final colour = colours.first();

        vtxBuffer
            .addFloat3(_x               , _y + _frame.height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(_frame.u1, _frame.v2)
            .addFloat3(_x + _frame.width, _y + _frame.height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(_frame.u2, _frame.v2)
            .addFloat3(_x               , _y                , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(_frame.u1, _frame.v1)
            .addFloat3(_x + _frame.width, _y                , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(_frame.u2, _frame.v1);
        idxBuffer
            .addInt(vtxCount + 0).addInt(vtxCount + 1).addInt(vtxCount + 2).addInt(vtxCount + 2).addInt(vtxCount + 1).addInt(vtxCount + 3);

        vtxCount += 4;
    }

    public function drawSprite(_sprite : SpriteResource, _animation : String, _idx : Int, _x : Float, _y : Float, _xFlip : Bool, _yFlip : Bool)
    {
        if (requireFlush(_sprite.image, shaders.first(), Triangles, samplers.first()))
        {
            flush(texture, shaders.first(), primitive, samplers.first());

            texture   = _sprite.image;
            primitive = Triangles;
        }

        final frame  = _sprite.animations[_animation][_idx];
        final colour = colours.first();
        final u1     = if (_xFlip) frame.u2 else frame.u1;
        final u2     = if (_xFlip) frame.u1 else frame.u2;
        final v1     = if (_yFlip) frame.v2 else frame.v1;
        final v2     = if (_yFlip) frame.v1 else frame.v2;

        vtxBuffer
            .addFloat3(_x              , _y + frame.height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v2)
            .addFloat3(_x + frame.width, _y + frame.height, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v2)
            .addFloat3(_x              , _y               , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v1)
            .addFloat3(_x + frame.width, _y               , 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v1);
        idxBuffer
            .addInt(vtxCount + 0).addInt(vtxCount + 1).addInt(vtxCount + 2).addInt(vtxCount + 2).addInt(vtxCount + 1).addInt(vtxCount + 3);

        vtxCount += 4;
    }

    public function drawNineSlice(_frame : ImageFrameResource, _image : ImageResource, _x : Float, _y : Float, _w : Float, _h : Float, _top : Float, _left : Float, _bottom : Float, _right : Float)
    {
        if (requireFlush(_frame.image, shaders.first(), Triangles, samplers.first()))
        {
            flush(texture, shaders.first(), primitive, samplers.first());

            texture   = _frame.image;
            primitive = Triangles;
        }

        final x1 = _x + 0;
        final x2 = _x + _left;
        final x3 = _x + _w - _right;
        final x4 = _x + _w;

        final y1 = _y + 0;
        final y2 = _y + _top;
        final y3 = _y + _h - _bottom;
        final y4 = _y + _h;

        final u1 =  _frame.x / _image.width;
        final u2 = (_frame.x + _left) / _image.width;
        final u3 = (_frame.x + (_frame.width - _right)) / _image.width;
        final u4 = (_frame.x + _frame.width) / _image.width;

        final v1 =  _frame.y / _image.height;
        final v2 = (_frame.y + _top) / _image.height;
        final v3 = (_frame.y + (_frame.height - _bottom)) / _image.height;
        final v4 = (_frame.y + _frame.height) / _image.height;

        final colour = colours.first();

        vtxBuffer
            // Top Left
            .addFloat3(x1, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v2)
            .addFloat3(x2, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v2)
            .addFloat3(x1, y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v1)
            .addFloat3(x2, y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v1)

            // Top Middle
            .addFloat3(x2, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v2)
            .addFloat3(x3, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v2)
            .addFloat3(x2, y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v1)
            .addFloat3(x3, y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v1)

            // Top Right
            .addFloat3(x3, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v2)
            .addFloat3(x4, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u4, v2)
            .addFloat3(x3, y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v1)
            .addFloat3(x4, y1, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u4, v1)

            // Middle Left
            .addFloat3(x1, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v3)
            .addFloat3(x2, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v3)
            .addFloat3(x1, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v2)
            .addFloat3(x2, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v2)

            // Middle Middle
            .addFloat3(x2, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v3)
            .addFloat3(x3, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v3)
            .addFloat3(x2, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v2)
            .addFloat3(x3, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v2)

            // Middle Right
            .addFloat3(x3, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v3)
            .addFloat3(x4, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u4, v3)
            .addFloat3(x3, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v2)
            .addFloat3(x4, y2, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u4, v2)

            // Bottom Left
            .addFloat3(x1, y4, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v4)
            .addFloat3(x2, y4, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v4)
            .addFloat3(x1, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u1, v3)
            .addFloat3(x2, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v3)

            // Bottom Middle
            .addFloat3(x2, y4, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v4)
            .addFloat3(x3, y4, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v4)
            .addFloat3(x2, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u2, v3)
            .addFloat3(x3, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v3)

            // Bottom Right
            .addFloat3(x3, y4, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v4)
            .addFloat3(x4, y4, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u4, v4)
            .addFloat3(x3, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u3, v3)
            .addFloat3(x4, y3, 0).addFloat4(colour.x, colour.y, colour.z, colour.w).addFloat2(u4, v3);

        idxBuffer
            .addInts([ vtxCount + 0    , vtxCount + 1    , vtxCount + 2    , vtxCount + 2    , vtxCount + 1    , vtxCount + 3 ])
            .addInts([ vtxCount + 4 + 0, vtxCount + 4 + 1, vtxCount + 4 + 2, vtxCount + 4 + 2, vtxCount + 4 + 1, vtxCount + 4 + 3 ])
            .addInts([ vtxCount + 8 + 0, vtxCount + 8 + 1, vtxCount + 8 + 2, vtxCount + 8 + 2, vtxCount + 8 + 1, vtxCount + 8 + 3 ])

            .addInts([ vtxCount + 12 + 0, vtxCount + 12 + 1, vtxCount + 12 + 2, vtxCount + 12 + 2, vtxCount + 12 + 1, vtxCount + 12 + 3 ])
            .addInts([ vtxCount + 16 + 0, vtxCount + 16 + 1, vtxCount + 16 + 2, vtxCount + 16 + 2, vtxCount + 16 + 1, vtxCount + 16 + 3 ])
            .addInts([ vtxCount + 20 + 0, vtxCount + 20 + 1, vtxCount + 20 + 2, vtxCount + 20 + 2, vtxCount + 20 + 1, vtxCount + 20 + 3 ])

            .addInts([ vtxCount + 24 + 0, vtxCount + 24 + 1, vtxCount + 24 + 2, vtxCount + 24 + 2, vtxCount + 24 + 1, vtxCount + 24 + 3 ])
            .addInts([ vtxCount + 28 + 0, vtxCount + 28 + 1, vtxCount + 28 + 2, vtxCount + 28 + 2, vtxCount + 28 + 1, vtxCount + 28 + 3 ])
            .addInts([ vtxCount + 32 + 0, vtxCount + 32 + 1, vtxCount + 32 + 2, vtxCount + 32 + 2, vtxCount + 32 + 1, vtxCount + 32 + 3 ]);

        vtxCount += 9 * 4;
    }

    public function end()
    {
        if (vtxCount == 0)
        {
            return;
        }

        flush(texture, shaders.first(), primitive, samplers.first());
    }

    function requireFlush(_newTexture : ResourceID, _newShader : ResourceID, _newPrimitive : PrimitiveType, _newSampler : SamplerState)
    {
        return
            _newTexture != texture ||
            _newShader != shaders.first() ||
            _newPrimitive != primitive ||
            _newSampler != samplers.first();
    }

    function flush(_texture : ResourceID, _shader : ResourceID, _primitive : PrimitiveType, _sampler : SamplerState)
    {
        if (vtxCount <= 0)
        {
            return;
        }

        queue.add(new DrawCommand(
            [ new Geometry({ data : Indexed(vtxBuffer.vertexBlob(), idxBuffer.indexBlob()) }) ],
            camera,
            _primitive,
            None,
            target,
            _shader,
            [],
            [ _texture ],
            [ _sampler ],
            depthState,
            stencilState,
            BlendState.none
        ));

        reset();
    }

    function reset()
    {
        vtxCount  = 0;
        vtxBuffer = new VertexBlobBuilder();
        idxBuffer = new IndexBlobBuilder();
    }
}