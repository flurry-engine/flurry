package uk.aidanlee.flurry.api.gpu.painter;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
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

    public function drawNineSlice(_frame : ImageFrameResource, _image : ImageResource, _x : Float, _y : Float, _w : Float, _h : Float, _top : Float, _left : Float, _bottom : Float, _right : Float)
    {
        checkFlush(_image.id, Triangles);

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

        vtxBuffer
            // Top Left
            .addFloat3(x1, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v2)
            .addFloat3(x2, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v2)
            .addFloat3(x1, y1, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v1)
            .addFloat3(x2, y1, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v1)

            // Top Middle
            .addFloat3(x2, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v2)
            .addFloat3(x3, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v2)
            .addFloat3(x2, y1, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v1)
            .addFloat3(x3, y1, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v1)

            // Top Right
            .addFloat3(x3, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v2)
            .addFloat3(x4, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u4, v2)
            .addFloat3(x3, y1, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v1)
            .addFloat3(x4, y1, 0).addFloat4(1, 1, 1, 1).addFloat2(u4, v1)

            // Middle Left
            .addFloat3(x1, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v3)
            .addFloat3(x2, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v3)
            .addFloat3(x1, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v2)
            .addFloat3(x2, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v2)

            // Middle Middle
            .addFloat3(x2, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v3)
            .addFloat3(x3, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v3)
            .addFloat3(x2, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v2)
            .addFloat3(x3, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v2)

            // Middle Right
            .addFloat3(x3, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v3)
            .addFloat3(x4, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u4, v3)
            .addFloat3(x3, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v2)
            .addFloat3(x4, y2, 0).addFloat4(1, 1, 1, 1).addFloat2(u4, v2)

            // Bottom Left
            .addFloat3(x1, y4, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v4)
            .addFloat3(x2, y4, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v4)
            .addFloat3(x1, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u1, v3)
            .addFloat3(x2, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v3)

            // Bottom Middle
            .addFloat3(x2, y4, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v4)
            .addFloat3(x3, y4, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v4)
            .addFloat3(x2, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u2, v3)
            .addFloat3(x3, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v3)

            // Bottom Right
            .addFloat3(x3, y4, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v4)
            .addFloat3(x4, y4, 0).addFloat4(1, 1, 1, 1).addFloat2(u4, v4)
            .addFloat3(x3, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u3, v3)
            .addFloat3(x4, y3, 0).addFloat4(1, 1, 1, 1).addFloat2(u4, v3);

        idxBuffer
            .addInts([ vtxCount + 0, vtxCount + 1, vtxCount + 2, vtxCount + 2, vtxCount + 1, vtxCount + 3 ])
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