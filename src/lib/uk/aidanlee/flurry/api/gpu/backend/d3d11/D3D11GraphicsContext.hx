package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import Mat4;
import VectorMath;
import haxe.Exception;
import haxe.ds.Vector;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.D3D11Conversions;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.output.IndexOutput;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.output.VertexOutput;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.output.UniformOutput;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.ResourceID;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11Viewport;

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

    final currentUniformBlobs : Vector<Null<UniformBlob>>;

    var currentShader : ResourceID;

    var currentPage : ResourceID;

    var currentSurface : SurfaceID;

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
        unfCameraBlob       = new UniformBlob('flurry_matrices', new ArrayBufferView(192), []);
        nativeView          = new D3d11Viewport();
        currentUniformBlobs = new Vector(15);
        currentShader       = ResourceID.invalid;
        currentPage         = ResourceID.invalid;
        currentSurface      = SurfaceID.backbuffer;
        mapped              = false;
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
                        throw new Exception('No surface with an ID of ${ pipeline.surface } was found');
                    case target:
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
                                context.omSetRenderTarget(target.surfaceRenderView, target.depthStencilView);
                                context.iaSetVertexBuffer(0, vtxOutput.buffer, shader.inputStride, vtxOffset);
                                context.iaSetIndexBuffer(idxOutput.buffer, R16UInt, idxOffset);
                                context.iaSetInputLayout(shader.inputLayout);
                                context.vsSetShader(shader.vertexShader, null);
                                context.psSetShader(shader.pixelShader, null);

                                context.omSetDepthStencilState(pipeline.depthStencilState, 1);
                                context.omSetBlendState(pipeline.blendState, [ 1, 1, 1, 1 ], 0xffffffff);
                                context.iaSetPrimitiveTopology(pipeline.primitive);

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
        
                nativeView.topLeftX = _camera.viewport.x;
                nativeView.topLeftY = _camera.viewport.y;
                nativeView.width    = _camera.viewport.z;
                nativeView.height   = _camera.viewport.w;
                context.rsSetViewport(nativeView);

                switch shader.findVertexBlockLocation('flurry_matrices')
                {
                    case -1:
                        // Shader does not want camera matrices.
                    case location:
                        final proj     = makeCentredFrustumRH(0, _camera.size.x, 0, _camera.size.y, -100, 100);
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

                        currentUniformBlobs[location] = unfCameraBlob;
                }
        }
    }

    public function usePage(_id : ResourceID, _sampler : SamplerState)
    {
        if (currentPage == _id)
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

                currentPage    = _id;
                currentSurface = SurfaceID.backbuffer;

                context.psSetShaderResource(0, texture.shaderResourceView);
                context.psSetSampler(0, samplers.get(_sampler));
        }
    }

    public function useSurface(_id : SurfaceID, _sampler : SamplerState)
    {
        if (currentSurface == _id)
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
                currentSurface = _id;

                context.psSetShaderResource(0, surface.surfaceView);
                context.psSetSampler(0, samplers.get(_sampler));
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

            // TODO : Attach all textures to their appropriate position.

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

        currentPage    = ResourceID.invalid;
        currentShader  = ResourceID.invalid;
        currentSurface = SurfaceID.backbuffer;

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
}