package uk.aidanlee.flurry.api.gpu.painter;

import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;
import uk.aidanlee.flurry.api.resources.Resource.FontResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.gpu.batcher.BatcherState;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob.IndexBlobBuilder;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Transformation;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;

class Painter
{
    final queue : (_command : DrawCommand)->Void;
    
    final camera : Camera2D;

    var vtxCount : Int;

    var vtxBuffer : VertexBlobBuilder;

    var idxBuffer : IndexBlobBuilder;

    var shader : ResourceID;

    var texture : ResourceID;

    var primitive : PrimitiveType;

    public function new(_queue, _camera, _shader)
    {
        queue     = _queue;
        camera    = _camera;
        shader    = _shader;
        texture   = 0;
        primitive = Triangles;
    }

    public function begin()
    {
        reset();
    }

    public function drawRectangle(_x : Float, _y : Float, _width : Float, _height : Float)
    {
        checkFlush(texture, Triangles);
    }

    public function drawLine()
    {
        checkFlush(texture, Lines);
    }

    public function drawText(_font : FontResource, _x : Float, _y : Float, _size : Float, _text : String)
    {
        checkFlush(_font.image, Triangles);
    }

    public function drawFrame(_frame : ImageFrameResource, _x : Float, _y : Float)
    {
        checkFlush(_frame.image, Triangles);

        vtxBuffer
            .addFloat3(_x               , _y + _frame.height, 0).addFloat4(1, 1, 1, 1).addFloat2(_frame.u1, _frame.v2)
            .addFloat3(_x + _frame.width, _y + _frame.height, 0).addFloat4(1, 1, 1, 1).addFloat2(_frame.u2, _frame.v2)
            .addFloat3(_x               , _y                , 0).addFloat4(1, 1, 1, 1).addFloat2(_frame.u1, _frame.v1)
            .addFloat3(_x + _frame.width, _y                , 0).addFloat4(1, 1, 1, 1).addFloat2(_frame.u2, _frame.v1);
        idxBuffer
            .addInt(vtxCount + 0).addInt(vtxCount + 1).addInt(vtxCount + 2).addInt(vtxCount + 2).addInt(vtxCount + 1).addInt(vtxCount + 3);

        vtxCount += 4;
    }

    public function drawNineSlice(_frame : ImageFrameResource, _x : Float, _y : Float, _w : Float, _y : Float, _top : Float, _left : Float, _bottom : Float, _right : Float)
    {
        //
    }

    public function end()
    {
        if (vtxCount == 0)
        {
            return;
        }

        queue(new DrawCommand(
            [ new Geometry({ data : Indexed(vtxBuffer.vertexBlob(), idxBuffer.indexBlob()) }) ],
            camera,
            primitive,
            None,
            Backbuffer,
            shader,
            [],
            [ texture ],
            [ SamplerState.nearest ],
            DepthState.none,
            StencilState.none,
            BlendState.none
        ));
    }

    function checkFlush(_newTexture : ResourceID, _newPrimitive : PrimitiveType)
    {
        final needsFlush = (texture != _newTexture || primitive != _newPrimitive);

        if (needsFlush && vtxCount > 0)
        {
            queue(new DrawCommand(
                [ new Geometry({ data : Indexed(vtxBuffer.vertexBlob(), idxBuffer.indexBlob()) }) ],
                camera,
                primitive,
                None,
                Backbuffer,
                shader,
                [],
                [ texture ],
                [ SamplerState.nearest ],
                DepthState.none,
                StencilState.none,
                BlendState.none
            ));

            reset();
        }

        primitive = _newPrimitive;
        texture   = _newTexture;
    }

    function reset()
    {
        vtxCount  = 0;
        vtxBuffer = new VertexBlobBuilder();
        idxBuffer = new IndexBlobBuilder();
    }
}