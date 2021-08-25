package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import Mat4;
import VectorMath;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.api.gpu.backend.ogl3.OGL3Conversions;
import uk.aidanlee.flurry.api.gpu.backend.ogl3.output.UniformOutput;
import haxe.ds.Vector;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import haxe.Exception;
import opengl.OpenGL;
import opengl.OpenGL.*;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.resources.ResourceID;

class OGL3GraphicsContext extends GraphicsContext
{
    final uniformOutput : UniformOutput;

    final unfCameraBlob : UniformBlob;

    final pipelines : Vector<Null<PipelineState>>;

    final surfaces : Vector<Null<OGL3SurfaceInformation>>;

    final shaders : Map<ResourceID, OGL3ShaderInformation>;

    final textures : Map<ResourceID, GLuint>;

    final samplers : OGL3SamplerCache;

    final currentUniformBlobs : Vector<Null<UniformBlob>>;

    var currentShader : ResourceID;

    var currentPage : ResourceID;

    var currentSampler : SamplerState;

    var currentSurface : SurfaceID;

    var mapped : Bool;

    var baseIdxOffset : Int;

    public function new(_vtxOut, _idxOut, _unfOut, _pipelines, _surfaces, _shaders, _textures)
    {
        super(_vtxOut, _idxOut);

        uniformOutput  = _unfOut;
        unfCameraBlob  = new UniformBlob('flurry_matrices', new ArrayBufferView(64), []);
        pipelines      = _pipelines;
        surfaces       = _surfaces;
        shaders        = _shaders;
        textures       = _textures;
        samplers       = new OGL3SamplerCache();
        currentUniformBlobs = new Vector(16);
        currentShader  = ResourceID.invalid;
        currentPage    = ResourceID.invalid;
        currentSurface = SurfaceID.backbuffer;
        currentSampler = SamplerState.nearest;
        mapped         = false;
        baseIdxOffset  = 0;
    }

	public function usePipeline(_id : PipelineID)
    {
        switch pipelines.get(_id)
        {
            case null:
                throw new Exception('No pipeline with an ID of $_id was found.');
            case pipeline:
                switch surfaces.get(pipeline.surface)
                {
                    case null:
                        throw new Exception('No shader with an ID of ${ pipeline.shader } was found');
                    case target:
                        switch shaders.get(pipeline.shader)
                        {
                            case null:
                                throw new Exception('No shader with an ID of ${ pipeline.shader } was found');
                            case shader:
                                flush();
                                map();

                                vtxOutput.seek(shader.byteStride);
                                idxOutput.reset();

                                for (element in shader.elements)
                                {
                                    glEnableVertexAttribArray(element.index);
                                    glVertexAttribPointer(
                                        element.index,
                                        element.floatSize,
                                        GL_FLOAT,
                                        false,
                                        shader.byteStride,
                                        element.byteOffset);
                                }

                                glUseProgram(shader.program);
                                glBindFramebuffer(GL_FRAMEBUFFER, target.frameBuffer);

                                if (pipeline.blend.enabled)
                                {
                                    glEnable(GL_BLEND);
                                    glBlendFunc(getBlend(pipeline.blend.srcFactor), getBlend(pipeline.blend.dstFactor));
                                    glBlendEquation(getBlendEquation(pipeline.blend.op));
                                }
                                else
                                {
                                    glDisable(GL_BLEND);
                                }

                                if (pipeline.depth.enabled)
                                {
                                    glEnable(GL_DEPTH_TEST);
                                    glDepthFunc(getDepthFunction(pipeline.depth.func));
                                    glDepthMask(pipeline.depth.masking);
                                }
                                else
                                {
                                    glDisable(GL_DEPTH_TEST);
                                }

                                currentShader  = pipeline.shader;
                                currentPage    = ResourceID.invalid;
                                currentSurface = SurfaceID.backbuffer;
                        }
                }
        }
    }

	public function useCamera(_camera : Camera2D)
    {
        switch shaders.get(currentShader)
        {
            case null:
                throw new Exception('Current shader $currentShader has no information stored about it');
            case shader:
                flush();
                map();

                glViewport(
                    cpp.NativeMath.fastInt(_camera.viewport.x),
                    cpp.NativeMath.fastInt(_camera.viewport.y),
                    cpp.NativeMath.fastInt(_camera.viewport.z),
                    cpp.NativeMath.fastInt(_camera.viewport.w));

                if (shader.matrixLocation != -1)
                {
                    final proj     = makeFrustumOpenGL(0, _camera.size.x, _camera.size.y, 0, -100, 100);
                    final view     = make2D(_camera.pos, _camera.origin, _camera.scale, _camera.angle).inverse();
                    final combined = proj * view;
                    
                    final bytes = unfCameraBlob.buffer.buffer.getData();
                    final data  = (combined : Mat4Data);
                    untyped __global__.__hxcpp_memory_set_float(bytes,  0, data.c0.x);
                    untyped __global__.__hxcpp_memory_set_float(bytes,  4, data.c0.y);
                    untyped __global__.__hxcpp_memory_set_float(bytes,  8, data.c0.z);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 12, data.c0.w);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 16, data.c1.x);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 20, data.c1.y);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 24, data.c1.z);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 28, data.c1.w);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 32, data.c2.x);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 36, data.c2.y);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 40, data.c2.z);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 44, data.c2.w);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 48, data.c3.x);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 52, data.c3.y);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 56, data.c3.z);
                    untyped __global__.__hxcpp_memory_set_float(bytes, 60, data.c3.w);

                    currentUniformBlobs[shader.matrixLocation] = unfCameraBlob;
                }
        }
    }

	public function usePage(_id : ResourceID, _sampler : SamplerState)
    {
        if (currentPage == _id && currentSampler == _sampler)
        {
            return;
        }

        switch textures.get(_id)
        {
            case null:
                throw new Exception('No texture with an ID of $_id was found');
            case glTextureID:
                flush();
                map();

                currentPage    = _id;
                currentSampler = _sampler;
                currentSurface = SurfaceID.backbuffer;

                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, glTextureID);
                glBindSampler(0, samplers.get(_sampler));
        }
    }

	public function useSurface(_id : SurfaceID, _sampler : SamplerState)
    {
        if (currentSurface == _id && currentSampler == _sampler)
        {
            return;
        }

        switch surfaces.get(_id)
        {
            case null:
                throw new Exception('No surface with an ID of $_id was found');
            case surface:
                flush();
                map();

                currentPage    = ResourceID.invalid;
                currentSampler = _sampler;
                currentSurface = _id;

                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, surface.texture);
                glBindSampler(0, samplers.get(_sampler));
        }
    }

	public function useUniformBlob(_blob : UniformBlob)
    {
        switch shaders.get(currentShader)
        {
            case null:
                throw new Exception('Current shader $currentShader has no information stored about it');
            case shader:
                switch shader.findBlockIndexByName(_blob.name)
                {
                    case -1:
                        throw new Exception('Shader $currentShader does not use a uniform buffer called ${ _blob.name }');
                    case binding:
                        if (currentUniformBlobs[binding] != null)
                        {
                            // There is already a blob with the same name queued for uploading.
                            // We need to flush the current data before inserting the blob in the queue.
                            flush();
                            map();
                        }
        
                        currentUniformBlobs[binding] = _blob;
                }
        }
    }

	public function prepare()
    {
        idxOutput.offset(vtxOutput.getVerticesWritten());
    }

	public function flush()
    {
        final idxCount = idxOutput.getIndicesWritten();

        if (idxCount > 0)
        {
            uploadUniforms();

            unmap();

            glDrawElements(GL_TRIANGLES, idxCount, GL_UNSIGNED_SHORT, 0);

            prepare();
        }
    }

	public function close()
    {
        flush();

        vtxOutput.close();
        idxOutput.close();
        uniformOutput.close();

        currentPage    = ResourceID.invalid;
        currentShader  = ResourceID.invalid;
        currentSurface = SurfaceID.backbuffer;
        baseIdxOffset  = 0;

        for (i in 0...currentUniformBlobs.length)
        {
            currentUniformBlobs[i] = null;
        }
    }

    function uploadUniforms()
    {
        for (i in 0...currentUniformBlobs.length)
        {
            switch (currentUniformBlobs[i])
            {
                case null:
                    continue;
                case blob:
                    final byteOffset = uniformOutput.write(blob.buffer);

                    glBindBufferRange(GL_UNIFORM_BUFFER, i, uniformOutput.buffer, byteOffset, blob.buffer.byteLength);
            }
        }
    }

    function map()
    {
        if (mapped)
        {
            return;
        }

        vtxOutput.map();
        idxOutput.map();
        uniformOutput.map();

        mapped = true;
    }

    function unmap()
    {
        if (!mapped)
        {
            return;
        }

        vtxOutput.unmap();
        idxOutput.unmap();
        uniformOutput.unmap();

        mapped = false;
    }
}