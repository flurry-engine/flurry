package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import Mat4;
import haxe.Exception;
import haxe.ds.Vector;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.shaders.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.D3D11Conversions;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.output.IndexOutput;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.output.VertexOutput;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.output.UniformOutput;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.ResourceID;
import d3d11.structures.D3d11Rect;
import d3d11.structures.D3d11Viewport;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;

using uk.aidanlee.flurry.api.utils.OutputUtils;

class D3D11GraphicsContext extends GraphicsContext
{
    final context : D3d11DeviceContext1;

    final samplers : D3D11SamplerCache;

    final pipelines : Vector<Null<D3D11PipelineState>>;

    final surfaces : Vector<Null<D3D11SurfaceInformation>>;

    final shaders : Map<ResourceID, D3D11ShaderInformation>;

    final textures : Map<ResourceID, D3D11TextureInformation>;

    final unfOutput : UniformOutput;

    final unfCameraBlob : UniformBlob;

    final nativeView : D3d11Viewport;

    final nativeScissor : D3d11Rect;

    final currentUniformBlobs : Vector<Null<UniformBlob>>;
    
    final currentPages : Vector<ResourceID>;

    final currentSurfaces : Vector<SurfaceID>;

    final currentSamplers : Vector<SamplerState>;

    var currentShader : ResourceID;

    var mapped : Bool;

    public function new(_context, _samplers, _pipelines, _surfaces, _shaders, _textures, _vtxBuffer, _idxBuffer, _unfBuffer)
    {
        super(
            new VertexOutput(_context, _vtxBuffer),
            new IndexOutput(_context, _idxBuffer)
        );

        context             = _context;
        samplers            = _samplers;
        pipelines           = _pipelines;
        surfaces            = _surfaces;
        shaders             = _shaders;
        textures            = _textures;
        unfOutput           = new UniformOutput(context, _unfBuffer);
        unfCameraBlob       = new UniformBlob('flurry_matrices', new ArrayBufferView(64));
        nativeView          = new D3d11Viewport();
        nativeScissor       = new D3d11Rect();
        currentUniformBlobs = new Vector(16);
        currentPages        = new Vector(16);
        currentSurfaces     = new Vector(16);
        currentSamplers     = new Vector(16);
        currentShader       = ResourceID.invalid;
        mapped              = false;

        clearActiveSlots();
    }

	public function usePipeline(_id : PipelineID)
    {
        switch pipelines[_id]
        {
            case null:
                throw new Exception('No pipeline with an ID of $_id was found.');
            case pipeline:
                switch surfaces[pipeline.surface]
                {
                    case null:
                        throw new Exception('No surface with an ID of ${ pipeline.surface } was found');
                    case surface:
                        switch shaders.get(pipeline.shader)
                        {
                            case null:
                                throw new Exception('No shader with an ID of ${ pipeline.shader } was found');
                            case shader:
                                flush();
                                map();

                                final vtxOffset = vtxOutput.seek(shader.inputStride);
                                final idxOffset = idxOutput.reset();

                                // Set D3D state according to the pipeline.
                                // TODO: We should do our own state tracking to avoid re-setting expensive state.
                                context.iaSetVertexBuffer(0, vtxOutput.buffer, shader.inputStride, vtxOffset);
                                context.iaSetIndexBuffer(idxOutput.buffer, R16UInt, idxOffset);
                                context.iaSetInputLayout(shader.inputLayout);
                                context.iaSetPrimitiveTopology(pipeline.primitive);

                                context.vsSetShader(shader.vertexShader, null);
                                context.psSetShader(shader.pixelShader, null);

                                context.omSetRenderTarget(surface.surfaceRenderView, surface.depthStencilView);
                                context.omSetDepthStencilState(pipeline.depthStencilState, 1);
                                context.omSetBlendState(pipeline.blendState, null, 0xffffffff);

                                // Reset the clip state to fit the backbuffer
                                switch surfaces[SurfaceID.backbuffer]
                                {
                                    case null:
                                        throw new Exception('Backbuffer surface not found');
                                    case backbuffer:
                                        @:nullSafety(Off) {
                                            nativeScissor.left   = 0;
                                            nativeScissor.top    = 0;
                                            nativeScissor.right  = backbuffer.state.width;
                                            nativeScissor.bottom = backbuffer.state.height;
                                            context.rsSetScissorRect(nativeScissor);
                                        }
                                }

                                currentShader  = pipeline.shader;
                                
                                clearActiveSlots();
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
        
                nativeView.topLeftX = _camera.viewport.x;
                nativeView.topLeftY = _camera.viewport.y;
                nativeView.width    = _camera.viewport.z;
                nativeView.height   = _camera.viewport.w;
                nativeView.minDepth = 0;
                nativeView.maxDepth = 1;
                context.rsSetViewport(nativeView);

                switch shader.findVertexBlockLocation('flurry_matrices')
                {
                    case -1:
                        // Shader does not want camera matrices.
                    case location:
                        final proj     = makeCentredFrustumRH(0, _camera.size.x, 0, _camera.size.y, -100, 100);
                        final view     = make2D(_camera.pos, _camera.origin, _camera.scale, _camera.angle).inverse();
                        final combined = proj * view;
                        
                        unfCameraBlob.write(0, combined);

                        currentUniformBlobs[location] = unfCameraBlob;
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
            case texture:
                flush();
                map();

                currentPages[_slot] = _id;
                currentSamplers[_slot] = _sampler;
                currentSurfaces[_slot] = SurfaceID.invalid;

                context.psSetShaderResource(_slot, texture.shaderResourceView);
                context.psSetSampler(_slot, samplers.get(_sampler));
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

                context.psSetShaderResource(_slot, surface.surfaceView);
                context.psSetSampler(_slot, samplers.get(_sampler));
        }
    }

    public function useUniformBlob(_blob : UniformBlob)
    {
        switch shaders.get(currentShader)
        {
            case null:
                throw new Exception('Current shader $currentShader has no information stored about it');
            case shader:
                switch shader.findVertexBlockLocation(_blob.name)
                {
                    case -1:
                        throw new Exception('Shader $currentShader does not use a cbuffer called ${ _blob.name }');
                    case location:
                        if (currentUniformBlobs[location] != null)
                        {
                            // There is already a blob with the same name queued for uploading.
                            // We need to flush the current data before inserting the blob in the queue.
                            flush();
                            map();
                        }
        
                        currentUniformBlobs[location] = _blob;
                }
        }
    }

    @:nullSafety(Off)
    public function useScissorRegion(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        if (nativeScissor.left == _x && nativeScissor.top == _y && nativeScissor.right == (_x + _width) && nativeScissor.bottom == (_y + _height))
        {
            return;
        }

        flush();
        map();

        nativeScissor.left   = _x;
        nativeScissor.top    = _y;
        nativeScissor.right  = _x + _width;
        nativeScissor.bottom = _y + _height;
        context.rsSetScissorRect(nativeScissor);
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
            // Copy all blobs into the buffer and attach them to the context.
            uploadUniforms();

            // Ensure the buffers are unmapped and changes visible to the GPU.
            unmap();

            // Unindexed draws are not supported.
            final baseVtx = vtxOutput.getBaseVertex();
            final baseIdx = idxOutput.getBaseIndex();

            context.drawIndexed(idxCount, baseIdx, baseVtx);

            prepare();
        }
    }

    public function close()
    {
        flush();

        vtxOutput.close();
        idxOutput.close();
        unfOutput.close();

        // Reset state trackers

        clearActiveSlots();

        // Clear all uniform blobs.

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
                    final blockLocation  = i;
                    final constantOffset = unfOutput.write(blob.buffer);
                    final constantsSize  = bytesToAlignedShaderConstants(blob.buffer.byteLength);

                    context.vsSetConstantBuffer1(blockLocation, unfOutput.getBuffer(), constantOffset, constantsSize);
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
        unfOutput.map();

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
        unfOutput.unmap();

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