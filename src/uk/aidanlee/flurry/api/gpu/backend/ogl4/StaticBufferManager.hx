package uk.aidanlee.flurry.api.gpu.backend.ogl4;

import haxe.io.UInt32Array;
import haxe.io.UInt16Array;
import haxe.io.Float32Array;
import cpp.Stdlib.memcpy;
import sdl.SDL;
import opengl.GL.*;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.thread.JobQueue;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.utils.opengl.GLSyncWrapper;

using Safety;
using cpp.NativeArray;

/**
 * Managed upload, removing, and drawing static draw commands.
 */
class StaticBufferManager
{
    /**
     * The maximum number of threads for writing to buffers.
     */
    static final RENDERER_THREADS = #if flurry_ogl4_no_multithreading 1 #else Std.int(Maths.max(SDL.getCPUCount() - 2, 1)) #end;

    final forceIncludeGL : GLSyncWrapper;

    /**
     * The maximum number of vertices which can fix in the buffer.
     */
    final maxVertices : Int;

    /**
     * The maximum number of indices which can fix in the buffer.
     */
    final maxIndices : Int;

    /**
     * OpenGL buffer ID of the static buffer.
     */
    final glVbo : Int;

    /**
     * OpenGL buffer ID of the index buffer.
     */
    final glIbo : Int;

    /**
     * All of the uploaded ranges, keyed by their command ID.
     */
    final ranges : Map<Int, StaticBufferRange>;

    /**
     * Ranges to be removed to make space for a new range.
     */
    final rangesToRemove : Array<Int>;

    /**
     * Queue to distribute writing tasks to multiple threads
     */
    final jobQueue : JobQueue;

    /**
     * Current vertex write position for uploading new commands.
     */
    var vtxPosition : Int;

    /**
     * Current index write position for uploading new commands.
     */
    var idxPosition : Int;

    public function new(_vtxBufferSize : Int, _idxBufferSize : Int, _glVbo : Int, _glIbo : Int)
    {
        forceIncludeGL = new GLSyncWrapper();
        jobQueue       = new JobQueue(RENDERER_THREADS);
        maxVertices    = _vtxBufferSize;
        maxIndices     = _idxBufferSize;
        glVbo          = _glVbo;
        glIbo          = _glIbo;
        ranges         = [];
        rangesToRemove = [];
        vtxPosition    = 0;
        idxPosition    = 0;
    }

    /**
     * Upload a geometry draw command to the static buffer.
     * Will remove other ranges to make space.
     * @param _command Command to upload.
     */
    public function uploadGeometry(_command : GeometryDrawCommand)
    {
        if (_command.vertices > maxVertices || _command.indices > maxIndices)
        {
            throw 'command ${_command.id} too large to fit in static buffer';
        }

        if (_command.vertices > (maxVertices - vtxPosition) || _command.indices > (maxIndices - idxPosition))
        {
            rangesToRemove.resize(0);

            for (key => range in ranges)
            {
                if ((0 < (range.vtxPosition + range.vtxLength) && (0 + _command.vertices) > 0) || (0 < (range.idxPosition + range.idxLength) && (0 + _command.indices) > 0))
                {
                    rangesToRemove.push(key);
                }

                glDeleteBuffers(2, [ range.glCommandBuffer, range.glMatrixBuffer ]);
            }

            for (id in rangesToRemove)
            {
                ranges.remove(id);
            }
        }       

        if (!ranges.exists(_command.id))
        {
            var buffers = [ 0, 0 ];
            glCreateBuffers(buffers.length, buffers);

            // Distribute uploading the vertex data and generating command buffers to threads.
            // Vertex data is spread across RENDERER_THREADS - 1 so the command buffer uploading will have its own thread.

            // Distribute

            var vtxPtr    = new Float32Array(_command.vertices * 9);
            var idxPtr    = new UInt16Array(_command.indices);
            var split     = Maths.floor(_command.geometry.length / RENDERER_THREADS);
            var remainder = _command.geometry.length % RENDERER_THREADS;
            var range     = _command.geometry.length < RENDERER_THREADS ? _command.geometry.length : RENDERER_THREADS;

            for (i in 0...range)
            {
                var vtxIdx       = 0;
                var idxIdx       = 0;
                var geomStartIdx = split * i;
                var geomEndIdx   = geomStartIdx + (i != range - 1 ? split : split + remainder);

                for (j in 0...geomStartIdx)
                {
                    vtxIdx += _command.geometry[j].vertices.length * 9;
                    idxIdx += _command.geometry[j].indices.length;
                }

                jobQueue.queue(() -> {
                    for (j in geomStartIdx...geomEndIdx)
                    {
                        for (index in _command.geometry[j].indices)
                        {
                            idxPtr[idxIdx++] = index;
                        }

                        for (vertex in _command.geometry[j].vertices)
                        {
                            vtxPtr[vtxIdx++] = vertex.position.x;
                            vtxPtr[vtxIdx++] = vertex.position.y;
                            vtxPtr[vtxIdx++] = vertex.position.z;
                            vtxPtr[vtxIdx++] = vertex.color.r;
                            vtxPtr[vtxIdx++] = vertex.color.g;
                            vtxPtr[vtxIdx++] = vertex.color.b;
                            vtxPtr[vtxIdx++] = vertex.color.a;
                            vtxPtr[vtxIdx++] = vertex.texCoord.x;
                            vtxPtr[vtxIdx++] = vertex.texCoord.y;
                        }
                    }
                });
            }

            // Create command buffer
            var mdiCommands : Null<UInt32Array> = null;

            // thread
            jobQueue.queue(() -> {
                if (_command.indices > 0)
                {
                    mdiCommands = new UInt32Array(_command.geometry.length * 5);
                    var writePos     = 0;
                    var cmdVtxOffset = vtxPosition;
                    var cmdIdxOffset = idxPosition;

                    for (geom in _command.geometry)
                    {
                        mdiCommands[writePos++] = geom.indices.length;
                        mdiCommands[writePos++] = 1;
                        mdiCommands[writePos++] = cmdIdxOffset;
                        mdiCommands[writePos++] = cmdVtxOffset;
                        mdiCommands[writePos++] = 0;

                        cmdVtxOffset += geom.vertices.length;
                    }
                }
                else
                {
                    mdiCommands = new UInt32Array(_command.geometry.length * 4);
                    var writePos     = 0;
                    var cmdVtxOffset = 0;

                    for (geom in _command.geometry)
                    {
                        mdiCommands[writePos++] = geom.vertices.length;
                        mdiCommands[writePos++] = 1;
                        mdiCommands[writePos++] = cmdVtxOffset;
                        mdiCommands[writePos++] = 0;

                        cmdVtxOffset += geom.vertices.length;
                    }
                }
            });

            jobQueue.wait();

            glNamedBufferSubData(glVbo, vtxPosition * 9 * 4, vtxPtr.view.buffer.length, vtxPtr.view.buffer.getData());
            glNamedBufferSubData(glIbo, idxPosition * 2, idxPtr.view.buffer.length, idxPtr.view.buffer.getData());

            if (_command.indices > 0)
            {
                glNamedBufferStorage(buffers[0], _command.geometry.length * 20, mdiCommands.unsafe().view.buffer.getData(), 0);
            }
            else
            {
                glNamedBufferStorage(buffers[0], _command.geometry.length * 16, mdiCommands.unsafe().view.buffer.getData(), 0);
            }

            // Create matrix buffer
            var matrixBuffer = new Float32Array(32 + (_command.geometry.length * 16));
            glNamedBufferStorage(buffers[1], matrixBuffer.view.buffer.length, matrixBuffer.view.buffer.getData(), GL_DYNAMIC_STORAGE_BIT);

            // TODO : Add a new range entry to the map.
            ranges.set(_command.id, new StaticBufferRange(buffers[0], buffers[1], matrixBuffer, vtxPosition, idxPosition, _command.vertices, _command.indices, _command.geometry.length));

            vtxPosition += _command.vertices;
            idxPosition += _command.indices;
        }

        // Upload the model matrices for all geometry in the command.

        var split     = Maths.floor(_command.geometry.length / RENDERER_THREADS);
        var remainder = _command.geometry.length % RENDERER_THREADS;
        var range     = _command.geometry.length < RENDERER_THREADS ? _command.geometry.length : RENDERER_THREADS;
        var data      = get(_command).matrixBuffer.view.buffer.getData();
        for (i in 0...range)
        {
            var geomStartIdx = split * i;
            var geomEndIdx   = geomStartIdx + (i != range - 1 ? split : split + remainder);
            
            for (j in geomStartIdx...geomEndIdx)
            {
                jobQueue.queue(() -> {
                    memcpy(data.address(128 + (j * 64)), (_command.geometry[j].transformation.transformation : Float32Array).view.buffer.getData().address(0), 64);
                });
            }
        }

        jobQueue.wait();
    }

    /**
     * Upload a buffer draw command to the static buffer.
     * Will remove other ranges to make space.
     * @param _command Command to upload.
     */
    public function uploadBuffer(_command : BufferDrawCommand)
    {
        if (_command.vertices > maxVertices || _command.indices > maxIndices)
        {
            throw 'command ${_command.id} too large to fit in static buffer';
        }

        if (_command.vertices > (maxVertices - vtxPosition) || _command.indices > (maxIndices - idxPosition))
        {
            rangesToRemove.resize(0);

            for (key => range in ranges)
            {
                if ((0 < (range.vtxPosition + range.vtxLength) && (0 + _command.vertices) > 0) || (0 < (range.idxPosition + range.idxLength) && (0 + _command.indices) > 0))
                {
                    rangesToRemove.push(key);
                }

                glDeleteBuffers(2, [ range.glCommandBuffer, range.glMatrixBuffer ]);
            }

            for (id in rangesToRemove)
            {
                ranges.remove(id);
            }
        }

        if (!ranges.exists(_command.id))
        {
            var vtxRange = _command.vtxData.subarray(_command.vtxStartIndex, _command.vtxEndIndex);
            var idxRange = _command.idxData.subarray(_command.idxStartIndex, _command.idxEndIndex);
            glNamedBufferSubData(glVbo, vtxPosition * 9 * 4, vtxRange.length * 4, vtxRange.view.buffer.getData());
            glNamedBufferSubData(glIbo, idxPosition * 2    , idxRange.length * 2, idxRange.view.buffer.getData());

            // TODO : Create a matrix and command buffer for the draw command.
            var buffers = [ 0, 0 ];
            glCreateBuffers(buffers.length, buffers);

            // Create command buffer
            if (_command.indices > 0)
            {
                var mdiCommands  = new UInt32Array(5);
                var writePos     = 0;
                var cmdVtxOffset = vtxPosition;
                var cmdIdxOffset = idxPosition;

                mdiCommands[writePos++] = _command.indices;
                mdiCommands[writePos++] = 1;
                mdiCommands[writePos++] = cmdIdxOffset;
                mdiCommands[writePos++] = cmdVtxOffset;
                mdiCommands[writePos++] = 0;

                glNamedBufferStorage(buffers[0], 20, mdiCommands.view.buffer.getData(), 0);
            }
            else
            {
                var mdiCommands  = new UInt32Array(4);
                var writePos     = 0;
                var cmdVtxOffset = 0;

                mdiCommands[writePos++] = _command.vertices;
                mdiCommands[writePos++] = 1;
                mdiCommands[writePos++] = cmdVtxOffset;
                mdiCommands[writePos++] = 0;

                glNamedBufferStorage(buffers[0], 16, mdiCommands.view.buffer.getData(), 0);
            }

            ranges.set(_command.id, new StaticBufferRange(buffers[0], buffers[1], new Float32Array(48), vtxPosition, idxPosition, _command.vertices, _command.indices, 1));

            vtxPosition += _command.vertices;
            idxPosition += _command.indices;
        }

        var range        = ranges.get(_command.id);
        var matrixBuffer = range.matrixBuffer;
        memcpy(matrixBuffer.view.buffer.getData().address(128), (_command.model : Float32Array).view.buffer.getData().address(0), 64);
        glNamedBufferStorage(range.glMatrixBuffer, matrixBuffer.view.buffer.length, matrixBuffer.view.buffer.getData(), GL_DYNAMIC_STORAGE_BIT);
    }

    /**
     * Draw an uploaded draw command.
     * @param _command Command to draw.
     */
    public function draw(_command : DrawCommand)
    {
        if (_command.indices > 0)
        {
            untyped __cpp__('glMultiDrawElementsIndirect({0}, GL_UNSIGNED_SHORT, 0, {1}, 0)', _command.primitive.getPrimitiveType(), get(_command).drawCount);
        }
        else
        {
            untyped __cpp__('glMultiDrawArraysIndirect({0}, 0, {1}, 0)', _command.primitive.getPrimitiveType(), get(_command).drawCount);
        }
    }

    /**
     * Get information about an uploaded range.
     * @param _command Uploaded command to get info on.
     * @return StaticBufferRange
     */
    public function get(_command : DrawCommand) : StaticBufferRange
    {
        return ranges.get(_command.id).sure();
    }
}

/**
 * Represents an uploaded `DrawCommand` in the static buffer.
 */
private class StaticBufferRange
{
    /**
     * OpenGL buffer ID for the buffer to be bound to `GL_DRAW_INDIRECT_BUFFER` to provide draw commands.
     */
    public final glCommandBuffer : Int;

    /**
     * OpenGL buffer ID for the buffer to be bound to the default matrix ssbo.
     */
    public final glMatrixBuffer : Int;
    
    /**
     * Bytes to store matrices to be uploaded to the GPU.
     * 
     * Enough space for a projection, view, and `drawCount` model matrices.
     */
    public final matrixBuffer : Float32Array;

    /**
     * The vertex offset into the vertex buffer this draw command is found.
     */
    public final vtxPosition : Int;

    /**
     * The index offfset into the index buffer this draw command is found.
     */
    public final idxPosition : Int;

    /**
     * The number of vertices in this draw command.
     */
    public final vtxLength : Int;

    /**
     * The number of indices in this draw command.
     */
    public final idxLength : Int;

    /**
     * The number of draw calls to make for this draw command. Used for multi draw indirect functions.
     * 
     * Always 1 for `BufferDrawCommand`. Equal to the number of geometries for `GeometryDrawCommand`.
     */
    public final drawCount : Int;

    public function new(
        _glCommandBuffer : Int,
        _glMatrixBuffer : Int,
        _matrixBuffer : Float32Array,
        _vtxPosition : Int,
        _idxPosition : Int,
        _vtxLength : Int,
        _idxLength : Int,
        _drawCount : Int)
    {
        glCommandBuffer = _glCommandBuffer;
        glMatrixBuffer  = _glMatrixBuffer;
        matrixBuffer    = _matrixBuffer;
        vtxPosition     = _vtxPosition;
        idxPosition     = _idxPosition;
        vtxLength       = _vtxLength;
        idxLength       = _idxLength;
        drawCount       = _drawCount;
    }
}