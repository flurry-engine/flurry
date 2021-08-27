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
import uk.aidanlee.flurry.api.gpu.shaders.UniformBlob;
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

    final scissor : Vec4;

    var currentShader : ResourceID;

    var currentPages : Vector<ResourceID>;

    var currentSurfaces : Vector<SurfaceID>;

    var currentSamplers : Vector<SamplerState>;

    var mapped : Bool;

    public function new(_vtxOut, _idxOut, _unfOut, _pipelines, _surfaces, _shaders, _textures)
    {
        super(_vtxOut, _idxOut);

        uniformOutput  = _unfOut;
        unfCameraBlob  = new UniformBlob('flurry_matrices', new ArrayBufferView(64));
        pipelines      = _pipelines;
        surfaces       = _surfaces;
        shaders        = _shaders;
        textures       = _textures;
        samplers       = new OGL3SamplerCache();
        currentUniformBlobs = new Vector(16);
        scissor         = vec4(0);
        currentShader   = ResourceID.invalid;
        currentPages    = new Vector(16);
        currentSurfaces = new Vector(16);
        currentSamplers = new Vector(16);
        mapped          = false;
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
                    case surface:
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
                                glBindFramebuffer(GL_FRAMEBUFFER, surface.frameBuffer);

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

                                switch surfaces[SurfaceID.backbuffer]
                                {
                                    case null:
                                        throw new Exception('backbuffer not found');
                                    case backbuffer:
                                        glScissor(0, 0, backbuffer.state.width, backbuffer.state.height);
                                        scissor.x = 0;
                                        scissor.y = 0;
                                        scissor.z = backbuffer.state.width;
                                        scissor.w = backbuffer.state.height;
                                }

                                clearActiveSlots();

                                currentShader = pipeline.shader;
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
                    
                    unfCameraBlob.write(0, combined);

                    currentUniformBlobs[shader.matrixLocation] = unfCameraBlob;
                }
        }
    }

	public function usePage(_slot : Int, _id : ResourceID, _sampler : SamplerState)
    {
        if (currentSurfaces[_slot] == SurfaceID.invalid && currentPages[_slot] == _id && currentSamplers[_slot] == _sampler)
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

                currentPages[_slot] = _id;
                currentSamplers[_slot] = _sampler;
                currentSurfaces[_slot] = SurfaceID.invalid;

                glActiveTexture(GL_TEXTURE0 + _slot);
                glBindTexture(GL_TEXTURE_2D, glTextureID);
                glBindSampler(_slot, samplers.get(_sampler));
        }
    }

	public function useSurface(_slot : Int, _id : SurfaceID, _sampler : SamplerState)
    {
        if (currentSurfaces[_slot] == _id && currentPages[_slot] == ResourceID.invalid && currentSamplers[_slot] == _sampler)
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

                currentPages[_slot] = ResourceID.invalid;
                currentSamplers[_slot] = _sampler;
                currentSurfaces[_slot] = _id;

                glActiveTexture(GL_TEXTURE0 + _slot);
                glBindTexture(GL_TEXTURE_2D, surface.texture);
                glBindSampler(_slot, samplers.get(_sampler));
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

    public function useScissorRegion(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        if (vec4(_x, _y, _width, _height) == scissor)
        {
            return;
        }

        glScissor(_x, _y, _width, _height);
        scissor.x = _x;
        scissor.y = _y;
        scissor.z = _width;
        scissor.w = _height;
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

        clearActiveSlots();

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

    function clearActiveSlots()
    {
        for (i in 0...16)
        {
            currentPages[i] = ResourceID.invalid;
            currentSurfaces[i] = SurfaceID.invalid;
            currentSamplers[i] = cast -1;
        }
    }
}