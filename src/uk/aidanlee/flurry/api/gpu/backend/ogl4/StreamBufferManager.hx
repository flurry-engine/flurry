package uk.aidanlee.flurry.api.gpu.backend.ogl4;

import cpp.UInt8;
import cpp.UInt16;
import cpp.Float32;
import cpp.Pointer;
import cpp.Stdlib.memcpy;
import sdl.SDL;
import opengl.GL.glDrawArrays;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.thread.JobQueue;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.utils.opengl.GLSyncWrapper;

using uk.aidanlee.flurry.utils.opengl.GLConverters;
using cpp.NativeArray;

/**
 * Manages a triple buffered stream buffer.
 */
class StreamBufferManager
{
    /**
     * The maximum number of threads for writing to buffers.
     */
    static final RENDERER_THREADS = #if flurry_ogl4_no_multithreading 1 #else Std.int(Maths.max(SDL.getCPUCount() - 2, 1)) #end;

    final forceIncludeGL : GLSyncWrapper;

    /**
     * Standard identity matrix used for geometry commands model matrix.
     */
    final identityMatrix : Matrix;

    /**
     * Constant vector for transforming vertices before being uploaded.
     */
    final transformationVectors : Array<Vector3>;

    /**
     * Queue to distribute writing tasks to multiple threads
     */
    final jobQueue : JobQueue;

    /**
     * The base vertex offset into the buffer that the stream buffer starts.
     */
    final vtxBaseOffset : Int;

    /**
     * The base index offset into the buffer that the stream buffer starts.
     */
    final idxBaseOffset : Int;

    /**
     * The size of each vertex stream range.
     */
    final vtxRangeSize : Int;

    /**
     * The size of each index stream range.
     */
    final idxRangeSize : Int;

    /**
     * Pointer to each range in the vertex stream buffer.
     */
    final vtxBuffer : Pointer<Float32>;

    /**
     * Pointer to each range in the index stream buffer.
     */
    final idxBuffer : Pointer<UInt16>;

    /**
     * Each ranges vertex offset.
     */
    var commandVtxOffsets : Map<Int, Int>;

    /**
     * Each ranges index offset.
     */
    var commandIdxOffsets : Map<Int, Int>;

    /**
     * Model matrix for each range.
     * If the command is not a buffer command no model matrix will be stored.
     */
    var bufferModelMatrix : Map<Int, Matrix>;

    /**
     * Current vertex float write position.
     */
    var currentVtxTypePosition : Int;

    /**
     * Current index uint write position.
     */
    var currentIdxTypePosition : Int;

    /**
     * Current vertex write position.
     */
    var currentVertexPosition : Int;

    public function new(_vtxBaseOffset : Int, _idxBaseOffset : Int, _vtxRange : Int, _idxRange : Int, _vtxPtr : Pointer<UInt8>, _idxPtr : Pointer<UInt8>)
    {
        forceIncludeGL         = new GLSyncWrapper();
        transformationVectors  = [ for (i in 0...RENDERER_THREADS) new Vector3() ];
        jobQueue               = new JobQueue(RENDERER_THREADS);
        identityMatrix         = new Matrix();
        vtxBaseOffset          = _vtxBaseOffset;
        idxBaseOffset          = _idxBaseOffset;
        vtxRangeSize           = _vtxRange;
        idxRangeSize           = _idxRange;
        vtxBuffer              = _vtxPtr.reinterpret();
        idxBuffer              = _idxPtr.reinterpret();
        commandVtxOffsets      = [];
        commandIdxOffsets      = [];
        bufferModelMatrix      = [];
        currentVtxTypePosition = 0;
        currentIdxTypePosition = 0;
        currentVertexPosition  = 0;
    }

    /**
     * Returns a model matrix for the provided command ID.
     * If the command id does not belong to an uploaded buffer command an identity matrix is returned.
     * @param _id Geometry command.
     * @return Matrix
     */
    public function getModelMatrix(_id : Int) : Matrix
    {
        if (bufferModelMatrix.exists(_id))
        {
            return bufferModelMatrix.get(_id);
        }
        else
        {
            return identityMatrix;
        }
    }

    /**
     * Setup uploading to a specific stream buffer range.
     * Must be done at the beginning off each frame.
     * @param _currentRange Range to upload to.
     */
    public function unlockBuffers(_currentRange : Int)
    {
        currentVtxTypePosition = _currentRange * (vtxRangeSize * 9);
        currentVertexPosition  = _currentRange * vtxRangeSize;
        currentIdxTypePosition = _currentRange * idxRangeSize;
        commandVtxOffsets      = [];
        commandIdxOffsets      = [];
        bufferModelMatrix      = [];
    }

    /**
     * Upload a geometry draw command into the current range.
     * @param _command Command to upload.
     */
    public function uploadGeometry(_command : GeometryDrawCommand)
    {
        commandVtxOffsets.set(_command.id, vtxBaseOffset + currentVertexPosition);
        commandIdxOffsets.set(_command.id, idxBaseOffset + currentIdxTypePosition);

        var split     = Maths.floor(_command.geometry.length / RENDERER_THREADS);
        var remainder = _command.geometry.length % RENDERER_THREADS;
        var range     = _command.geometry.length < RENDERER_THREADS ? _command.geometry.length : RENDERER_THREADS;
        for (i in 0...range)
        {
            var geomStartIdx   = split * i;
            var geomEndIdx     = geomStartIdx + (i != range - 1 ? split : split + remainder);
            var idxValueOffset = 0;
            var idxWriteOffset = currentIdxTypePosition;
            var vtxWriteOffset = currentVtxTypePosition;

            for (j in 0...geomStartIdx)
            {
                idxValueOffset += _command.geometry[j].vertices.length;
                idxWriteOffset += _command.geometry[j].indices.length;
                vtxWriteOffset += _command.geometry[j].vertices.length * 9;
            }

            jobQueue.queue(() -> {
                for (j in geomStartIdx...geomEndIdx)
                {
                    for (index in _command.geometry[j].indices)
                    {
                        idxBuffer[idxWriteOffset++] = idxValueOffset + index;
                    }

                    for (vertex in _command.geometry[j].vertices)
                    {
                        // Copy the vertex into another vertex.
                        // This allows us to apply the transformation without permanently modifying the original geometry.
                        transformationVectors[i].copyFrom(vertex.position);
                        transformationVectors[i].transform(_command.geometry[j].transformation.world.matrix);

                        vtxBuffer[vtxWriteOffset++] = transformationVectors[i].x;
                        vtxBuffer[vtxWriteOffset++] = transformationVectors[i].y;
                        vtxBuffer[vtxWriteOffset++] = transformationVectors[i].z;
                        vtxBuffer[vtxWriteOffset++] = vertex.color.r;
                        vtxBuffer[vtxWriteOffset++] = vertex.color.g;
                        vtxBuffer[vtxWriteOffset++] = vertex.color.b;
                        vtxBuffer[vtxWriteOffset++] = vertex.color.a;
                        vtxBuffer[vtxWriteOffset++] = vertex.texCoord.x;
                        vtxBuffer[vtxWriteOffset++] = vertex.texCoord.y;
                    }

                    idxValueOffset += _command.geometry[j].vertices.length;
                }
            });
        }

        for (geom in _command.geometry)
        {
            currentIdxTypePosition += geom.indices.length;
            currentVtxTypePosition += geom.vertices.length * 9;
            currentVertexPosition  += geom.vertices.length;
        }

        jobQueue.wait();
    }

    /**
     * Upload a buffer draw command into the current range.
     * @param _command 
     */
    public function uploadBuffer(_command : BufferDrawCommand)
    {
        commandVtxOffsets.set(_command.id, vtxBaseOffset + currentVertexPosition);
        commandIdxOffsets.set(_command.id, idxBaseOffset + currentIdxTypePosition);
        bufferModelMatrix.set(_command.id, _command.model);

        memcpy(
            idxBuffer.incBy(currentIdxTypePosition),
            _command.idxData.view.buffer.getData().address(_command.idxStartIndex * 2),
            _command.indices * 2);
        memcpy(
            vtxBuffer.incBy(currentVtxTypePosition),
            _command.vtxData.view.buffer.getData().address(_command.vtxStartIndex * 9 * 4),
            _command.vertices * 9 * 4);

        idxBuffer.incBy(-currentIdxTypePosition);
        vtxBuffer.incBy(-currentVtxTypePosition);

        currentIdxTypePosition += _command.indices;
        currentVtxTypePosition += _command.vertices * 9;
        currentVertexPosition  += _command.vertices;
    }

    /**
     * Draw an uploaded draw command.
     * @param _command Command to draw.
     */
    public function draw(_command : DrawCommand)
    {
        // Draw the actual vertices
        if (_command.indices > 0)
        {
            var idxOffset = commandIdxOffsets.get(_command.id) * 2;
            var vtxOffset = commandVtxOffsets.get(_command.id);
            untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', _command.primitive.getPrimitiveType(), _command.indices, GL_UNSIGNED_SHORT, idxOffset, vtxOffset);
        }
        else
        {
            var vtxOffset = commandVtxOffsets.get(_command.id);
            glDrawArrays(_command.primitive.getPrimitiveType(), vtxOffset, _command.vertices);
        }
    }
}