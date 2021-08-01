package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import haxe.Exception;
import haxe.ds.Vector;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
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

    final shaders : Map<ResourceID, D3D11ShaderInformation>;

    final textures : Map<ResourceID, D3D11TextureInformation>;

    final unfOutput : UniformOutput;

    final nativeView : D3d11Viewport;

    final currentUniformBlobs : Vector<Null<UniformBlob>>;

    final currentUniformLocations : Vector<Int>;

    var currentPipeline : PipelineID;

    var currentShader : ResourceID;

    var currentPage : ResourceID;

    var mapped : Bool;

    public function new(_context, _samplers, _pipelines, _shaders, _textures, _vtxBuffer, _idxBuffer, _unfBuffer)
    {
        super(
            new VertexOutput(_context, _vtxBuffer),
            new IndexOutput(_context, _idxBuffer)
        );

        context                 = _context;
        samplers                = _samplers;
        pipelines               = _pipelines;
        shaders                 = _shaders;
        textures                = _textures;
        unfOutput               = new UniformOutput(context, _unfBuffer);
        nativeView              = new D3d11Viewport();
        currentUniformBlobs     = new Vector(14);
        currentUniformLocations = new Vector(14);
        currentPipeline         = PipelineID.invalid;
        currentShader           = ResourceID.invalid;
        currentPage             = ResourceID.invalid;
        mapped                  = false;

        for (i in 0...currentUniformLocations.length)
        {
            currentUniformLocations[i] = -1;
        }
    }

	public function usePipeline(_id : PipelineID)
    {
        if (currentPipeline == _id)
        {
            return;
        }

        switch pipelines.get(_id)
        {
            case null:
                throw new Exception('No pipeline with an ID of $_id was found.');
            case pipeline:
                switch shaders.get(pipeline.shader)
                {
                    case null:
                        throw new Exception('No shader with an ID of ${ pipeline.shader } was found');
                    case shader:
                        flush();
                        map();
    
                        // Set D3D state according to the pipeline.
                        context.iaSetInputLayout(shader.inputLayout);
                        context.vsSetShader(shader.vertexShader, null);
                        context.psSetShader(shader.pixelShader, null);
    
                        context.omSetDepthStencilState(pipeline.depthStencilState, 1);
                        context.omSetBlendState(pipeline.blendState, [ 1, 1, 1, 1 ], 0xffffffff);
                        context.iaSetPrimitiveTopology(pipeline.primitive);
    
                        currentPipeline = _id;
                        currentShader   = pipeline.shader;
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

                final location = shader.findVertexBlockLocation('flurry_matrices');
                final proj     = makeFrustum(0, _camera.size.x, 0, _camera.size.y, -100, 100);
                final view     = make2D(_camera.pos.x, _camera.pos.y);
                final model    = identity();

                unfOutput.write(proj);
                unfOutput.write(view);
                unfOutput.write(model);
        
                context.vsSetConstantBuffer1(location, unfOutput.getBuffer(), 0, 256);
        }
    }

    public function usePage(_id : ResourceID)
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

                currentPage = _id;

                final sampler = samplers.get(SamplerState.nearest);

                context.psSetShaderResources(0, [ texture.shaderResourceView ]);
                context.psSetSamplers(0, [ sampler ]);
        }
    }

    public function useUniformBlob(_blob : UniformBlob)
    {
        for (i in 0...currentUniformBlobs.length)
        {
            final blob = currentUniformBlobs[i];
            if (blob != null)
            {
                if (blob.id == _blob.id)
                {
                    // There is already a blob with the same name queued for uploading.
                    // We need to flush the current data before inserting the blob in the queue.
                    flush();
                    map();
    
                    currentUniformBlobs[i] = blob;

                    return;
                }
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
            // Ensure the buffers are unmapped and changes visible to the GPU.
            unmap();

            // TODO : Attach all uniform blocks to their appropriate position.

            // TODO : Attach all textures to their appropriate position.

            // Unindexed draws are not supported.
            context.drawIndexed(idxCount, 0, 0);

            prepare();
        }
    }

    public function close()
    {
        flush();

        // Reset state trackers

        currentPipeline = PipelineID.invalid;
        currentPage     = ResourceID.invalid;

        // Clear all uniform blobs.

        for (i in 0...currentUniformBlobs.length)
        {
            currentUniformBlobs[i] = null;
        }

        for (i in 0...currentUniformLocations.length)
        {
            currentUniformLocations[i] = -1;
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