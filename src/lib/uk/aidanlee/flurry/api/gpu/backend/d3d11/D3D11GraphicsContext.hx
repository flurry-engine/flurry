package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import haxe.Exception;
import haxe.ds.Vector;
import haxe.io.Output;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.resources.ResourceID;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11Device.D3d11Device1;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;
import d3d11.structures.D3d11Viewport;
import d3d11.structures.D3d11MappedSubResource;

using Safety;
using uk.aidanlee.flurry.api.utils.OutputUtils;

class D3D11GraphicsContext extends GraphicsContext
{
    final device : D3d11Device1;

    final context : D3d11DeviceContext1;

    final pipelines : Vector<Null<D3D11PipelineState>>;

    final shaders : Map<ResourceID, D3D11ShaderInformation>;

    final textures : Map<ResourceID, D3D11TextureInformation>;

    final vtxBuffer : D3D11MappableOutput;

    final idxBuffer : D3D11MappableIndexOutput;

    final unfBuffer : D3D11MappableOutput;

    final currentUniformBlobs : Vector<Null<UniformBlob>>;

    final currentUniformLocations : Vector<Int>;

    var currentPipeline : PipelineID;

    var currentPage : ResourceID;

    public function new(_device, _context, _pipelines, _shaders, _textures, _vtxBuffer, _idxBuffer, _unfBuffer)
    {
        device                  = _device;
        context                 = _context;
        pipelines               = _pipelines;
        shaders                 = _shaders;
        textures                = _textures;
        vtxBuffer               = new D3D11MappableOutput(4 * 9, context, _vtxBuffer);
        idxBuffer               = new D3D11MappableIndexOutput(context, _idxBuffer);
        unfBuffer               = new D3D11MappableOutput(4, context, _unfBuffer);
        currentUniformBlobs     = new Vector(14);
        currentUniformLocations = new Vector(14);
        currentPipeline         = PipelineID.invalid;
        currentPage             = ResourceID.invalid;

        for (i in 0...currentUniformLocations.length)
        {
            currentUniformLocations[i] = -1;
        }
    }

	public function usePipeline(_id : PipelineID)
    {
        if (currentPipeline != _id)
        {
            final newPipeline = pipelines[_id];

            if (newPipeline != null)
            {
                final shader = shaders.get(newPipeline.shader);

                if (shader != null)
                {
                    flush();

                    vtxBuffer.map();
                    idxBuffer.map();
                    unfBuffer.map();

                    // Set D3D state according to the pipeline.
                    context.iaSetInputLayout(shader.inputLayout);
                    context.vsSetShader(shader.vertexShader, null);
                    context.psSetShader(shader.pixelShader, null);

                    context.omSetDepthStencilState(newPipeline.depthStencilState, 1);
                    context.omSetBlendState(newPipeline.blendState, [ 1, 1, 1, 1 ], 0xffffffff);
                    context.iaSetPrimitiveTopology(newPipeline.primitive);

                    currentPipeline = _id;
                }
                else
                {
                    throw new Exception('No shader with an ID of ${ newPipeline.shader } was found');
                }
            }
            else
            {
                throw new Exception('No pipeline with an ID of $_id was found.');
            }
        }
    }

    public function useCamera(_camera : Camera2D)
    {
        flush();

        vtxBuffer.map();
        idxBuffer.map();
        unfBuffer.map();

        // Set the viewport.
        final view = new D3d11Viewport();
        view.topLeftX = _camera.viewport.x;
        view.topLeftY = _camera.viewport.y;
        view.width    = _camera.viewport.z;
        view.height   = _camera.viewport.w;

        context.rsSetViewport(view);

        // Create the camera matrices.
        final proj  = makeFrustum(0, _camera.size.x, 0, _camera.size.y, -100, 100);
        final view  = make2D(_camera.pos.x, _camera.pos.y);
        final model = identity();

        // Create a combined view * projection matrix and upload it
        final shaderID   = pipelines[currentPipeline].unsafe().shader;
        final shaderInfo = shaders[shaderID].unsafe();
        final location   = shaderInfo.findVertexBlockLocation('flurry_matrices');

        unfBuffer.writeMatrix(proj);
        unfBuffer.writeMatrix(view);
        unfBuffer.writeMatrix(model);

        context.vsSetConstantBuffer1(location, unfBuffer.buffer, 0, 256);
    }

    public function usePage(_id : ResourceID)
    {
        if (currentPage != _id)
        {
            flush();

            currentPage = _id;

            final texture = textures[currentPage].unsafe();
            final sampler = texture.getOrCreateSampler(device, SamplerState.nearest);

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

                    vtxBuffer.map();
                    idxBuffer.map();
                    unfBuffer.map();
    
                    currentUniformBlobs[i] = blob;

                    return;
                }
            }
        }
    }

    public function prepare()
    {
        idxBuffer.baseIndex = vtxBuffer.getElementsWritten();
    }

    public function flush()
    {
        final vtxCount = vtxBuffer.getElementsWritten();
        final idxCount = idxBuffer.getElementsWritten();

        if (idxCount > 0)
        {
            // Ensure the buffers are unmapped and changes visible to the GPU.
            vtxBuffer.unmap();
            idxBuffer.unmap();
            unfBuffer.unmap();

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

	function get_vtxOutput() : Output
    {
		return vtxBuffer;
	}

	function get_idxOutput() : Output
    {
		return idxBuffer;
	}
}

private class D3D11MappableOutput extends Output
{
    public final buffer : D3d11Buffer;

    final elementSize : Int;

    final context : D3d11DeviceContext1;

    final mappedResource : D3d11MappedSubResource;

    var bytesWritten : Int;

    public function new(_elementSize, _context, _buffer)
    {
        elementSize       = _elementSize;
        context           = _context;
        buffer            = _buffer;
        mappedResource    = new D3d11MappedSubResource();
        bytesWritten      = 0;
    }

    public function getBytesWritten()
    {
        return bytesWritten;
    }

    public function getElementsWritten()
    {
        return Std.int(bytesWritten / elementSize);
    }

    public function map()
    {
        var result = Ok;
        if (Ok != (result = context.map(buffer, 0, WriteDiscard, 0, mappedResource)))
        {
            throw new Exception('Failed to map D3D11 resource, HRESULT $result');
        }
    }

    public function unmap()
    {
        context.unmap(buffer, 0);
    }

    public override function writeByte(_byte : Int)
    {
        final ptr = @:nullSafety(Off) mappedResource.backing.data;

        untyped __cpp__('*((unsigned char*){0} + {1}) = {2}', ptr, bytesWritten, _byte);

        bytesWritten = bytesWritten + 1;
    }

    public override function writeFloat(_float : Float)
    {
        final ptr = @:nullSafety(Off) mappedResource.backing.data;

        untyped __cpp__('int idx = {0} / 4', bytesWritten);
        untyped __cpp__('*((float*){0} + idx) = {1}', ptr, _float);

        bytesWritten = bytesWritten + 4;
    }

    public override function writeUInt16(_int : Int)
    {
        final ptr = @:nullSafety(Off) mappedResource.backing.data;

        untyped __cpp__('int idx = {0} / 2', bytesWritten);
        untyped __cpp__('*((unsigned short*){0} + idx) = {1}', ptr, _int);

        bytesWritten = bytesWritten + 2;
    }

    public override function writeInt16(_int : Int)
    {
        final ptr = @:nullSafety(Off) mappedResource.backing.data;

        untyped __cpp__('int idx = {0} / 2', bytesWritten);
        untyped __cpp__('*((signed short*){0} + idx) = {1}', ptr, _int);

        bytesWritten = bytesWritten + 2;
    }
}

private class D3D11MappableIndexOutput extends D3D11MappableOutput
{
    public var baseIndex : Int;

    public function new(_context, _buffer)
    {
        super(2, _context, _buffer);

        baseIndex = 0;
    }

    public override function writeInt16(x : Int)
    {
        super.writeUInt16(baseIndex + x);
    }

    override function writeUInt16(x : Int)
    {
        super.writeUInt16(baseIndex + x);
    }

    public override function flush()
    {
        super.flush();

        baseIndex = 0;
    }
}