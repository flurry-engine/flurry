package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import d3d11.interfaces.D3d11Device.D3d11Device1;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import haxe.io.Output;
import d3d11.constants.D3d11Error;
import haxe.Exception;
import VectorMath;
import Mat4;
import d3d11.structures.D3d11Viewport;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import d3d11.structures.D3d11MappedSubResource;
import uk.aidanlee.flurry.api.resources.ResourceID;
import haxe.ds.Vector;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext.D3d11DeviceContext1;

@:nullSafety(Off) class D3D11GraphicsContext extends GraphicsContext
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

        // Create the camera view.
        final theta = 0;
        final scale = 1;
        final c     = Math.cos(theta);
        final s     = Math.sin(theta);
        final view  = mat4(
             c * scale, s * scale,  0, _camera.pos.x,
            -s * scale, c * scale,  0, _camera.pos.y,
                     0,         0,  1,  0,
                     0,         0,  0,  1
        ).transpose();

        // Create the camera projection.
        // Orthographic projection, D3D NDC z space (0 - 1)
        final left   = 0;
        final right  = _camera.size.x;
        final top    = 0;
        final bottom = _camera.size.y;
        final near   = -100;
        final far    = 100;

        final a      =  2 / (right - left);
        final b      =  2 / (top - bottom);
        final c      = -2 / (far - near);
        final proj   = mat4(
            a, 0, 0, - (right + left) / (right - left),
            0, b, 0, - (top + bottom) / (top - bottom),
            0, 0, c, - (far + near) / (far - near),
            0, 0, 0, 1
        ).transpose();

        final model = mat4(1);

        // Create a combined view * projection matrix and upload it
        final shaderID   = pipelines[currentPipeline].shader;
        final shaderInfo = shaders[shaderID];
        final location   = shaderInfo.findVertexBlockLocation('flurry_matrices');

        final matrix = (proj : Mat4Data);
        unfBuffer.writeFloat(matrix.c0.x);
        unfBuffer.writeFloat(matrix.c0.y);
        unfBuffer.writeFloat(matrix.c0.z);
        unfBuffer.writeFloat(matrix.c0.w);
        unfBuffer.writeFloat(matrix.c1.x);
        unfBuffer.writeFloat(matrix.c1.y);
        unfBuffer.writeFloat(matrix.c1.z);
        unfBuffer.writeFloat(matrix.c1.w);
        unfBuffer.writeFloat(matrix.c2.x);
        unfBuffer.writeFloat(matrix.c2.y);
        unfBuffer.writeFloat(matrix.c2.z);
        unfBuffer.writeFloat(matrix.c2.w);
        unfBuffer.writeFloat(matrix.c3.x);
        unfBuffer.writeFloat(matrix.c3.y);
        unfBuffer.writeFloat(matrix.c3.z);
        unfBuffer.writeFloat(matrix.c3.w);

        final matrix = (view : Mat4Data);
        unfBuffer.writeFloat(matrix.c0.x);
        unfBuffer.writeFloat(matrix.c0.y);
        unfBuffer.writeFloat(matrix.c0.z);
        unfBuffer.writeFloat(matrix.c0.w);
        unfBuffer.writeFloat(matrix.c1.x);
        unfBuffer.writeFloat(matrix.c1.y);
        unfBuffer.writeFloat(matrix.c1.z);
        unfBuffer.writeFloat(matrix.c1.w);
        unfBuffer.writeFloat(matrix.c2.x);
        unfBuffer.writeFloat(matrix.c2.y);
        unfBuffer.writeFloat(matrix.c2.z);
        unfBuffer.writeFloat(matrix.c2.w);
        unfBuffer.writeFloat(matrix.c3.x);
        unfBuffer.writeFloat(matrix.c3.y);
        unfBuffer.writeFloat(matrix.c3.z);
        unfBuffer.writeFloat(matrix.c3.w);

        final matrix = (model : Mat4Data);
        unfBuffer.writeFloat(matrix.c0.x);
        unfBuffer.writeFloat(matrix.c0.y);
        unfBuffer.writeFloat(matrix.c0.z);
        unfBuffer.writeFloat(matrix.c0.w);
        unfBuffer.writeFloat(matrix.c1.x);
        unfBuffer.writeFloat(matrix.c1.y);
        unfBuffer.writeFloat(matrix.c1.z);
        unfBuffer.writeFloat(matrix.c1.w);
        unfBuffer.writeFloat(matrix.c2.x);
        unfBuffer.writeFloat(matrix.c2.y);
        unfBuffer.writeFloat(matrix.c2.z);
        unfBuffer.writeFloat(matrix.c2.w);
        unfBuffer.writeFloat(matrix.c3.x);
        unfBuffer.writeFloat(matrix.c3.y);
        unfBuffer.writeFloat(matrix.c3.z);
        unfBuffer.writeFloat(matrix.c3.w);

        context.vsSetConstantBuffer1(location, unfBuffer.buffer, 0, 256);
    }

    public function usePage(_id : ResourceID)
    {
        if (currentPage != _id)
        {
            flush();

            currentPage = _id;

            final texture = textures[currentPage];
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

	function get_vtxOutput():Output {
		return vtxBuffer;
	}

	function get_idxOutput():Output {
		return idxBuffer;
	}
}

private class D3D11MappableOutput extends Output
{
    public final buffer : D3d11Buffer;

    final elementSize : Int;

    final context : D3d11DeviceContext1;

    final mappedResource : D3d11MappedSubResource;

    var pointer : Null<cpp.Pointer<cpp.UInt8>>;

    var bytesWritten : Int;

    public function new(_elementSize, _context, _buffer)
    {
        elementSize       = _elementSize;
        context           = _context;
        buffer            = _buffer;
        mappedResource    = new D3d11MappedSubResource();
        pointer           = null;
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

        pointer = @:nullSafety(Off) mappedResource.data.reinterpret();
    }

    public function unmap()
    {
        context.unmap(buffer, 0);
    }

    public override function writeByte(_byte : Int)
    {
        if (pointer != null)
        {
            pointer[bytesWritten++] = _byte;
        }
        else
        {
            throw new Exception('Mapped buffer pointer is null');
        }
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