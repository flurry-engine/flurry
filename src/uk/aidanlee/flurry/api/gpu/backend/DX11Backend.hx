package uk.aidanlee.flurry.api.gpu.backend;

import haxe.io.Bytes;
import haxe.ds.Map;
import sdl.Window;
import sdl.SDL;
import haxe.io.Float32Array;
import directx.DirectX;
import dxgi.SwapChainDescription;
import dxgi.SwapChain;
import dxgi.DXGI;
import dxgi.Factory;
import dxgi.Output;
import dxgi.Adapter;
import d3dcompiler.D3DCompiler;
import d3dcommon.D3DCommon;
import d3dcommon.Blob;
import d3d11.resources.Texture2D;
import d3d11.resources.Texture2DDescription;
import d3d11.resources.Buffer;
import d3d11.resources.BufferDescription;
import d3d11.resources.ShaderResourceView;
import d3d11.resources.RenderTargetView;
import d3d11.DeviceContext;
import d3d11.Device;
import d3d11.Viewport;
import d3d11.D3D11;
import d3d11.SubResourceData;
import d3d11.MappedSubResource;
import d3d11.InputLayout;
import d3d11.InputElementDescription;
import d3d11.PixelShader;
import d3d11.VertexShader;
import d3d11.RasterizerState;
import d3d11.BlendDescription;
import d3d11.RasterizerDescription;
import d3d11.BlendState;
import d3d11.SamplerState;
import d3d11.SamplerDescription;
import d3d11.Rect;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.Resource.ShaderType;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Matrix;

using cpp.Native;

@:headerCode('
#include <D3Dcompiler.h>
#include "SDL_syswm.h"
')
class DX11Backend implements IRendererBackend
{
    /**
     * Event bus for the rendering backend to listen to resource creation events.
     */
    final events : EventBus;

    /**
     * Access to the renderer which owns this backend.
     */
    final rendererStats : RendererStats;

    /**
     * Constant vector instance which is used to transform vertices when copying into the vertex buffer.
     */
    final transformationVector : Vector;

    /**
     * Tracks the position and number of vertices for draw commands uploaded into the dynamic buffer.
     */
    final dynamicCommandRanges : Map<Int, DrawCommandRange>;

    /**
     * D3D11 device for this window.
     */
    var device : Device;

    /**
     * Main D3D11 context for this windows device.
     */
    var context : DeviceContext;

    /**
     * DXGI swapchain for presenting the backbuffer to the window.
     */
    var swapchain : SwapChain;

    /**
     * Single main vertex buffer.
     */
    var vertexBuffer : Buffer;

    /**
     * Single main index buffer.
     */
    var indexBuffer : Buffer;

    /**
     * Native D3D viewport struct.
     */
    var nativeView : Viewport;

    /**
     * Native D3D scissor clip struct.
     */
    var nativeClip : Rect;

    /**
     * Native D3D blend description struct.
     */
    var blendDescription : BlendDescription;

    /**
     * Native D3D rasteriser description struct.
     */
    var rasterDescription : RasterizerDescription;

    /**
     * Native D3D blend state interface.
     */
    var blendState : BlendState;

    /**
     * Native D3D raster state interface.
     */
    var rasterState : RasterizerState;

    /**
     * Representation of the backbuffer.
     * Used as a default render target.
     */
    var backbuffer : BackBuffer;

    /**
     * The render target currently active.
     */
    var renderTarget : RenderTargetView;

    /**
     * Map of shader name to the D3D11 resources required to use the shader.
     */
    var shaderResources : Map<String, DXShaderInformation>;

    /**
     * Map of texture name to the D3D11 resources required to use the texture.
     */
    var textureResources : Map<String, DXTextureInformation>;

    /**
     * Map of target IDs to the D3D11 resources required to use the target.
     */
    var targetResources : Map<String, RenderTargetView>;

    /**
     * Sequence number render texture IDs.
     * For each generated render texture this number is incremented and given to the render texture as a unique ID.
     * Allows batchers to sort render textures.
     */
    var targetSequence : Int;

    /**
     * The number of vertices that have been written into the vertex buffer this frame.
     */
    var vertexOffset : Int;

    /**
     * The number of 32bit floats that have been written into the vertex buffer this frame.
     */
    var vertexFloatOffset : Int;

    /**
     * The number of indices that have been written into the index buffer this frame.
     */
    var indexOffset : Int;

    // State trackers
    var viewport : Rectangle;
    var scissor  : Rectangle;
    var topology : PrimitiveType;
    var shader   : ShaderResource;
    var texture  : ImageResource;
    var target   : ImageResource;

    // Event listener IDs

    final evResourceCreated : Int;

    final evResourceRemoved : Int;

    // SDL Window

    var window : Window;

    public function new(_events : EventBus, _rendererStats : RendererStats, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        events           = _events;
        rendererStats    = _rendererStats;

        createWindow(_windowConfig);

        var success         = false;
        var adapterIdx      = 0;
        var outputIdx       = 0;
        var hwnd : com.HWND = null;

        untyped __cpp__('SDL_SysWMinfo info;
        SDL_VERSION(&info.version);
        SDL_GetWindowWMInfo({1}, &info);
        {0} = SDL_DXGIGetOutputInfo(SDL_GetWindowDisplayIndex({1}), &{2}, &{3});
        {4} = info.info.win.window', success, window, adapterIdx, outputIdx, hwnd);

        if (!success)
        {
            throw 'Unable to get DXGI information for the main SDL window';
        }

        shaderResources  = new Map();
        textureResources = new Map();
        targetResources  = new Map();

        // Causes HxCPP to include the linc_directx build xml to properly link against directx libs
        DirectX.include();

        // Setup the DXGI factory and get this windows adapter and output.
        var factory : Factory = null;
        var adapter : Adapter = null;
        var output  : Output  = null;

        if (DXGI.createFactory(cast factory.addressOf()) != 0)
        {
            throw 'DXGI Failure creating factory';
        }
        if (factory.enumAdapters(adapterIdx, cast adapter.addressOf()) != 0)
        {
            throw 'DXGI Failure enumerating adapter $adapterIdx';
        }
        if (adapter.enumOutputs(outputIdx, cast output.addressOf()) != 0)
        {
            throw 'DXGI Failure enumerating output $outputIdx';
        }

        // Create the device, context, and swapchain.
        var description = SwapChainDescription.create();
        description.bufferDescription.width  = _windowConfig.width;
        description.bufferDescription.height = _windowConfig.height;
        description.bufferDescription.format = R8G8B8A8_UNORM;
        description.sampleDescription.count  = 1;
        description.outputWindow = hwnd;
        description.bufferCount  = 1;
        description.bufferUsage  = DXGI.USAGE_RENDER_TARGET_OUTPUT;
        description.windowed     = true;

        // Create our actual device and swapchain
        if (D3D11.createDevice(adapter, cast device.addressOf(), cast context.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create D3D11 device';
        }
        if (factory.createSwapChain(device, cast description.addressOf(), cast swapchain.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create DXGI swapchain';
        }

        // Release now un-needed DXGI resources
        factory.release();
        adapter.release();
        output.release();

        // Create the backbuffer render target.
        backbuffer = new BackBuffer(_windowConfig.width, _windowConfig.height, 1);

        var texture : Texture2D = null;
        if (swapchain.getBuffer(0, cast texture.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to get the swapchain backbuffer';
        }
        if (device.createRenderTargetView(texture, null, cast backbuffer.renderTargetView.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create render target view for the backbuffer';
        }
        texture.release();

        // Create the default viewport
        nativeView = Viewport.create();
        nativeView.topLeftX = 0;
        nativeView.topLeftY = 0;
        nativeView.width    = _windowConfig.width;
        nativeView.height   = _windowConfig.height;

        // Create the default clip
        nativeClip = Rect.create();
        nativeClip.top    = 0;
        nativeClip.left   = 0;
        nativeClip.right  = _windowConfig.width;
        nativeClip.bottom = _windowConfig.height;

        // Setup the rasterizer state.
        rasterDescription = RasterizerDescription.create();
        rasterDescription.fillMode              = SOLID;
        rasterDescription.cullMode              = NONE;
        rasterDescription.frontCounterClockwise = false;
        rasterDescription.depthBias             = 0;
        rasterDescription.slopeScaledDepthBias  = 0;
        rasterDescription.depthBiasClamp        = 0;
        rasterDescription.depthClipEnabled      = true;
        rasterDescription.scissorEnable         = true;
        rasterDescription.multisampleEnable     = false;
        rasterDescription.antialiasedLineEnable = false;

        if (device.createRasterizerState(cast rasterDescription.addressOf(), cast rasterState.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create rasterizer state';
        }

        // Setup the initial blend state
        blendDescription = BlendDescription.create();
        blendDescription.alphaToCoverageEnable  = false;
        blendDescription.independentBlendEnable = false;
        blendDescription.renderTarget[0].blendEnable    = true;
        blendDescription.renderTarget[0].srcBlend       = SRC_ALPHA;
        blendDescription.renderTarget[0].srcBlendAlpha  = ONE;
        blendDescription.renderTarget[0].destBlend      = INV_SRC_ALPHA;
        blendDescription.renderTarget[0].destBlendAlpha = ZERO;
        blendDescription.renderTarget[0].blendOp        = ADD;
        blendDescription.renderTarget[0].blendOpAlpha   = ADD;
        blendDescription.renderTarget[0].renderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE.ALL;

        if (device.createBlendState(cast blendDescription.addressOf(), cast blendState.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create blend state';
        }

        // Create our (initially) empty vertex buffer.
        var bufferDesc = BufferDescription.create();
        bufferDesc.byteWidth      = (_rendererConfig.dynamicVertices + _rendererConfig.unchangingVertices) * 9;
        bufferDesc.usage          = DYNAMIC;
        bufferDesc.bindFlags      = VERTEX_BUFFER;
        bufferDesc.cpuAccessFlags = WRITE;

        if (device.createBuffer(cast bufferDesc.addressOf(), null, cast vertexBuffer.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create vertex buffer';
        }

        var bufferDesc = BufferDescription.create();
        bufferDesc.byteWidth      = (_rendererConfig.dynamicIndices + _rendererConfig.unchangingIndices) * 2;
        bufferDesc.usage          = DYNAMIC;
        bufferDesc.bindFlags      = INDEX_BUFFER;
        bufferDesc.cpuAccessFlags = WRITE;

        if (device.createBuffer(cast bufferDesc.addressOf(), null, cast indexBuffer.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create index buffer';
        }

        targetSequence++;

        // Set the initial context state.
        var stride = (9 * 4);
        var offset = 0;
        context.iaSetIndexBuffer(indexBuffer, R16_UINT, offset);
        context.iaSetVertexBuffers(0, [ vertexBuffer ], [ stride ], [ offset ]);
        context.iaSetPrimitiveTopology(TRIANGLELIST);
        context.rsSetViewports([ nativeView ]);
        context.rsSetScissorRects([ nativeClip ]);
        context.rsSetState(rasterState);
        context.omSetRenderTargets([ backbuffer.renderTargetView ], null);

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;

        transformationVector = new Vector();
        dynamicCommandRanges = new Map();

        // Setup initial state tracker
        viewport = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        scissor  = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        topology = PrimitiveType.Triangles;
        target   = null;
        shader   = null;
        texture  = null;

        // Listen to resource creation events.
        evResourceCreated = events.listen(ResourceEvents.Created, onResourceCreated);
        evResourceRemoved = events.listen(ResourceEvents.Removed, onResourceRemoved);
    }

    public function clear()
    {
        context.clearRenderTargetView(backbuffer.renderTargetView, [ 0.2, 0.2, 0.2, 1.0 ]);
    }

    public function clearUnchanging()
    {
        //
    }

    public function preDraw()
    {
        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void
    {
        // Map the buffer.
        var mappedVtxBuffer = MappedSubResource.create();
        if (context.map(vertexBuffer, 0, WRITE_DISCARD, 0, cast mappedVtxBuffer.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to map vertex buffer';
        }

        var mappedIdxBuffer = MappedSubResource.create();
        if (context.map(indexBuffer, 0, WRITE_DISCARD, 0, cast mappedIdxBuffer.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to map index buffer';
        }

        // Get a buffer to float32s so we can copy our float32array over.
        var vtx : cpp.Pointer<cpp.Float32> = cpp.Pointer.fromRaw(mappedVtxBuffer.sysMem).reinterpret();
        var idx : cpp.Pointer<cpp.UInt16>  = cpp.Pointer.fromRaw(mappedIdxBuffer.sysMem).reinterpret();

        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, command.indices, indexOffset));

            var rangeIndexOffset = 0;
            for (geom in command.geometry)
            {
                var matrix = geom.transformation.transformation;

                for (index in geom.indices)
                {
                    idx[indexOffset++] = rangeIndexOffset + index;
                }

                for (vertex in geom.vertices)
                {
                    // Copy the vertex into another vertex.
                    // This allows us to apply the transformation without permanently modifying the original geometry.
                    transformationVector.copyFrom(vertex.position);
                    transformationVector.transform(matrix);

                    vtx[vertexFloatOffset++] = transformationVector.x;
                    vtx[vertexFloatOffset++] = transformationVector.y;
                    vtx[vertexFloatOffset++] = transformationVector.z;
                    vtx[vertexFloatOffset++] = vertex.color.r;
                    vtx[vertexFloatOffset++] = vertex.color.g;
                    vtx[vertexFloatOffset++] = vertex.color.b;
                    vtx[vertexFloatOffset++] = vertex.color.a;
                    vtx[vertexFloatOffset++] = vertex.texCoord.x;
                    vtx[vertexFloatOffset++] = vertex.texCoord.y;
                }

                vertexOffset     += geom.vertices.length;
                rangeIndexOffset += geom.vertices.length;
            }
        }

        context.unmap(vertexBuffer, 0);
        context.unmap(indexBuffer, 0);
    }

    /**
     * Upload buffer data to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>) : Void
    {
        // Map the buffer.
        var mappedBuffer = MappedSubResource.create();
        if (context.map(vertexBuffer, 0, WRITE_DISCARD, 0, cast mappedBuffer.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to map vertex buffer';
        }

        // Get a buffer to float32s so we can copy our float32array over.
        var ptr : cpp.Pointer<cpp.Float32> = cpp.Pointer.fromRaw(mappedBuffer.sysMem).reinterpret();

        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, 0, 0));

            for (i in command.startIndex...command.endIndex)
            {
                ptr[vertexFloatOffset++] = command.buffer[i];
            }

            vertexOffset += command.vertices;
        }

        context.unmap(vertexBuffer, 0);
    }

    /**
     * Draw an array of commands. Command data must be uploaded to the GPU before being used.
     * @param _commands    Commands to draw.
     * @param _recordStats Record stats for this submit.
     */
    public function submitCommands(_commands : Array<DrawCommand>, _recordStats : Bool = true) : Void
    {
        for (command in _commands)
        {
            var range = dynamicCommandRanges.get(command.id);

            // Set context state
            setState(command);

            // Draw
            if (command.indices > 0)
            {
                context.drawIndexed(command.indices, range.indexOffset, range.vertexOffset);
            }
            else
            {
                context.draw(range.vertices, range.vertexOffset);
            }

            // Record stats
            if (_recordStats)
            {
                rendererStats.dynamicDraws++;
                rendererStats.totalVertices += command.vertices;
            }
        }
    }

    /**
     * Present our backbuffer to the window.
     */
    public function postDraw()
    {
        swapchain.present(0, 0);
    }

    /**
     * Resize the backbuffer and re-assign the backbuffer pointer.
     * @param _width  New width of the window.
     * @param _height New height of the window.
     */
    public function resize(_width : Int, _height : Int)
    {
        backbuffer.width  = _width;
        backbuffer.height = _height;
        backbuffer.renderTargetView.release();

        if (swapchain.resizeBuffers(0, _width, _height, DXGI_FORMAT.UNKNOWN, 0) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to resize the swapchain';
        }

        // Create a texture target from the backbuffer
        var texture : Texture2D = null;

        if (swapchain.getBuffer(0, cast texture.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to get the swapchain backbuffer';
        }
        if (device.createRenderTargetView(texture, null, cast backbuffer.renderTargetView.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create render target view for the backbuffer';
        }

        // Release the temp texture and set the backbuffer to our filled out buffer.
        // Not sure why we need the temp buffer, doesn't work without it.
        texture.release();

        // If we don't force a render target change here then the previous backbuffer pointer might still be bound and used.
        // This would cause nothing to render since that old backbuffer has now been released.
        context.omSetRenderTargets([ backbuffer.renderTargetView ], null);
        target = null;

        rendererStats.targetSwaps++;
    }

    /**
     * Release all DX11 interface pointers.
     */
    public function cleanup()
    {
        
        for (shaderID in shaderResources.keys())
        {
            var resources = shaderResources.get(shaderID);

            resources.vertex.release();
            resources.pixel.release();
            resources.input.release();

            for (buffer in resources.buffers)
            {
                buffer.release();
            }

            shaderResources.remove(shaderID);
        }

        for (textureID in textureResources.keys())
        {
            var resources = textureResources.get(textureID);

            resources.srv.release();
            resources.tex.release();
            resources.smp.release();

            if (targetResources.exists(textureID))
            {
                var rtv = targetResources.get(textureID);
                rtv.release();

                targetResources.remove(textureID);
            }

            textureResources.remove(textureID);
        }

        rasterState.release();
        blendState.release();
        vertexBuffer.release();

        backbuffer.renderTargetView.release();
        swapchain.release();
        context.release();
        device.release();

        SDL.destroyWindow(window);
    }

    // #region SDL Window Management

    function createWindow(_options : FlurryWindowConfig)
    {        
        window = SDL.createWindow('Flurry', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
    }

    // #endregion

    // #region resource handling

    function onResourceCreated(_event : ResourceEventCreated)
    {
        switch (_event.type)
        {
            case ImageResource:
                createTexture(cast _event.resource);
            case ShaderResource:
                createShader(cast _event.resource);
            case _:
                //
        }
    }

    function onResourceRemoved(_event : ResourceEventRemoved)
    {
        switch (_event.type)
        {
            case ImageResource:
                removeTexture(cast _event.resource);
            case ShaderResource:
                removeShader(cast _event.resource);
            case _:
                //
        }
    }

    /**
     * Create the D3D11 resources required for a shader.
     * @param _vert   Vertex source.
     * @param _frag   Pixel source.
     * @param _layout JSON shader layout description.
     * @return Shader
     */
    function createShader(_resource : ShaderResource)
    {
        if (_resource.hlsl == null)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Attempting to create a shader from a resource which has no hlsl shader source';
        }

        if (shaderResources.exists(_resource.id))
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Attempting to create a shader which already exists';
        }

        // Compile the HLSL vertex shader
        var vertexBytecode : Blob = null;
        var vertexErrors   : Blob = null;
        if (D3DCompiler.compile(_resource.hlsl.vertex, "VShader", "vs_4_0", cast vertexBytecode.addressOf(), cast vertexErrors.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to compile vertex shader';
        }

        // Compile the HLSL pixel shader
        var pixelBytecode : Blob = null;
        var pixelErrors   : Blob = null;
        if (D3DCompiler.compile(_resource.hlsl.fragment, "PShader", "ps_4_0", cast pixelBytecode.addressOf(), cast pixelErrors.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to compile pixel shader';
        }

        // Create the vertex shader
        var vertexShader : VertexShader = null;
        if (device.createVertexShader(vertexBytecode.getBufferPointer(), vertexBytecode.getBufferSize(), null, cast vertexShader.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create vertex shader';
        }

        // Create the fragment shader
        var pixelShader : PixelShader = null;
        if (device.createPixelShader(pixelBytecode.getBufferPointer(), pixelBytecode.getBufferSize(), null, cast pixelShader.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create pixel shader';
        }

        // Create an input layout.
        var inputDescriptor = InputElementDescriptionArray.create();
        inputDescriptor.add("POSITION", 0, R32G32B32_FLOAT   , 0,  0, PER_VERTEX_DATA, 0);
        inputDescriptor.add("COLOR"   , 0, R32G32B32A32_FLOAT, 0, 12, PER_VERTEX_DATA, 0);
        inputDescriptor.add("TEXCOORD", 0, R32G32_FLOAT      , 0, 28, PER_VERTEX_DATA, 0);

        var inputLayout : InputLayout = null;
        if (device.createInputLayout(inputDescriptor, vertexBytecode.getBufferPointer(), vertexBytecode.getBufferSize(), cast inputLayout.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to creating input layout';
        }

        // Release the blob bytecode.
        vertexBytecode.release();
        pixelBytecode.release();

        // Create a initial cbuffer to store our two required matricies in them.
        var bufferDesc = BufferDescription.create();
        bufferDesc.byteWidth      = (64 * 2);
        bufferDesc.usage          = DYNAMIC;
        bufferDesc.bindFlags      = CONSTANT_BUFFER;
        bufferDesc.cpuAccessFlags = WRITE;

        var defaultBuffer : Buffer = null;
        if (device.createBuffer(bufferDesc, null, cast defaultBuffer.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create default matrix cbuffer';
        }

        // Create our shader and a class to store its resources.
        var resource = new DXShaderInformation();
        resource.layout  = _resource.layout;
        resource.vertex  = vertexShader;
        resource.pixel   = pixelShader;
        resource.input   = inputLayout;

        resource.bytes   = [];
        resource.buffers = new Map();
        resource.buffers.set(0, defaultBuffer);
        
        // Create a D3D cbuffer for each of our user defined blocks
        for (i in 0..._resource.layout.blocks.length)
        {
            var bytesSize = 0;
            for (val in _resource.layout.blocks[i].vals)
            {
                switch (ShaderType.createByName(val.type))
                {
                    case Matrix4: bytesSize += 64;
                    case Vector4: bytesSize += 16;
                    case Int    : bytesSize +=  4;
                }
            }

            var bytesData  = Bytes.alloc(bytesSize);
            var bufferDesc = BufferDescription.create();
            bufferDesc.byteWidth      = bytesSize;
            bufferDesc.usage          = DYNAMIC;
            bufferDesc.bindFlags      = CONSTANT_BUFFER;
            bufferDesc.cpuAccessFlags = WRITE;

            var buffer : Buffer = null;
            if (device.createBuffer(bufferDesc, null, cast buffer.addressOf()) != 0)
            {
                throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create cbuffer $i';
            }

            resource.buffers.set(i + 1, buffer);
            resource.bytes.push(bytesData);
        }

        shaderResources.set(_resource.id, resource);
    }

    /**
     * Remove the D3D11 resources used by a shader.
     * @param _name Name of the shader to remove.
     */
    function removeShader(_resource : ShaderResource)
    {
        var resources = shaderResources.get(_resource.id);

        resources.vertex.release();
        resources.pixel.release();
        resources.input.release();

        for (buffer in resources.buffers)
        {
            buffer.release();
        }

        shaderResources.remove(_resource.id);
    }

    /**
     * Create the D3D11 resources needed for a texture.
     * @param _pixels Raw image RGBA data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
    function createTexture(_resource : ImageResource)
    {
        // Sub resource struct to hold the raw image bytes.
        var imgData = SubResourceData.create();
        imgData.sysMem           = untyped __cpp__('(const void *)&({0}[0])', _resource.pixels);
        imgData.sysMemPitch      = 4 * _resource.width;
        imgData.sysMemSlicePitch = 0;

        // Texture description struct. Describes how our raw image data is formated and usage of the texture.
        var imgDesc = Texture2DDescription.create();
        imgDesc.width     = _resource.width;
        imgDesc.height    = _resource.height;
        imgDesc.mipLevels = 1;
        imgDesc.arraySize = 1;
        imgDesc.format    = R8G8B8A8_UNORM;
        imgDesc.sampleDesc.count   = 1;
        imgDesc.sampleDesc.quality = 0;
        imgDesc.usage          = DEFAULT;
        imgDesc.bindFlags      = SHADER_RESOURCE;
        imgDesc.cpuAccessFlags = 0;
        imgDesc.miscFlags      = 0;

        // Setup this images sampler. Will describe how HLSL samples texture data in shaders.
        var samplerDescription = SamplerDescription.create();
        samplerDescription.filter = MIN_MAG_MIP_POINT;
        samplerDescription.addressU = CLAMP;
        samplerDescription.addressV = CLAMP;
        samplerDescription.addressW = CLAMP;
        samplerDescription.mipLODBias    = 0;
        samplerDescription.maxAnisotropy = 1;
        samplerDescription.comparisonFunc = NEVER;
        samplerDescription.borderColor[0] = 1;
        samplerDescription.borderColor[1] = 1;
        samplerDescription.borderColor[2] = 1;
        samplerDescription.borderColor[3] = 1;
        samplerDescription.minLOD = -1;
        samplerDescription.minLOD =  1;

        var img : Texture2D          = null;
        var srv : ShaderResourceView = null;
        var smp : SamplerState       = null;

        if (device.createTexture2D(cast imgDesc.addressOf(), cast imgData.addressOf(), cast img.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create Texture2D';
        }
        if (device.createShaderResourceView(img, null, cast srv.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create shader resource view';
        }
        if (device.createSamplerState(samplerDescription, cast smp.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create sampler state';
        }

        var resource = new DXTextureInformation();
        resource.tex = img;
        resource.srv = srv;
        resource.smp = smp;

        textureResources.set(_resource.id, resource);
    }

    /**
     * Free the D3D11 resources used by a texture.
     * @param _name Name of the texture to remove.
     */
    function removeTexture(_resource : ImageResource)
    {
        var resources = textureResources.get(_resource.id);

        resources.srv.release();
        resources.tex.release();
        resources.smp.release();

        if (targetResources.exists(_resource.id))
        {
            var rtv = targetResources.get(_resource.id);
            rtv.release();

            targetResources.remove(_resource.id);
        }

        textureResources.remove(_resource.id);
    }

    // #endregion

    /**
     * Sets the state of the D3D11 context to draw the provided command.
     * Will check against the current state to prevent unneeded state changes.
     * @param _command Command to get state info from.
     */
    function setState(_command : DrawCommand)
    {
        // Update viewport
        var cmdView = _command.viewport != null ? _command.viewport : new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        if (!viewport.equals(cmdView))
        {
            viewport.copyFrom(cmdView);

            nativeView.topLeftX = viewport.x;
            nativeView.topLeftY = viewport.y;
            nativeView.width    = viewport.w;
            nativeView.height   = viewport.h;
            context.rsSetViewports([ nativeView ]);

            rendererStats.viewportSwaps++;
        }

        // Update scissor
        if (!scissor.equals(_command.clip))
        {
            scissor.copyFrom(_command.clip);

            nativeClip.left   = cast scissor.x;
            nativeClip.top    = cast scissor.y;
            nativeClip.right  = cast scissor.w;
            nativeClip.bottom = cast scissor.h;

            // If the clip rectangle has an area of 0 then set the width and height to that of the viewport
            // This essentially disables clipping by clipping the entire backbuffer size.
            if (scissor.area() == 0)
            {
                nativeClip.right  = backbuffer.width;
                nativeClip.bottom = backbuffer.height;
            }

            context.rsSetScissorRects([ nativeClip ]);

            rendererStats.scissorSwaps++;
        }

        // Set the render target
        if (_command.target != target)
        {
            if (target != null && !targetResources.exists(target.id))
            {
                var rtv : RenderTargetView = null;
                if (device.createRenderTargetView(textureResources.get(_command.target.id).tex, null, cast rtv.addressOf()) != 0)
                {
                    throw 'Failed to create render target view';
                }

                targetResources.set(_command.target.id, rtv);
            }

            target = _command.target;

            renderTarget = target == null ? backbuffer.renderTargetView : targetResources.get(target.id);
            context.omSetRenderTargets([ renderTarget ], null);

            rendererStats.targetSwaps++;
        }

        // Always update the cbuffers and textures for now
        setShaderValues(_command);

        // Write shader cbuffers and set it
        if (shader != _command.shader)
        {
            shader = _command.shader;

            // Apply the actual shader and input layout.
            var shaderResource = shaderResources.get(_command.shader.id);

            context.iaSetInputLayout(shaderResource.input);
            context.vsSetShader(shaderResource.vertex, null, 0);
            context.psSetShader(shaderResource.pixel , null, 0);

            rendererStats.shaderSwaps++;
        }

        // SET BLENDING OPTIONS AND APPLY TO CONTEXT
        if (_command.blending)
        {
            blendDescription.renderTarget[0].blendEnable    = true;
            blendDescription.renderTarget[0].srcBlend       = getBlend(_command.srcRGB);
            blendDescription.renderTarget[0].srcBlendAlpha  = getBlend(_command.srcAlpha);
            blendDescription.renderTarget[0].destBlend      = getBlend(_command.dstRGB);
            blendDescription.renderTarget[0].destBlendAlpha = getBlend(_command.dstAlpha);
        }
        else
        {
            blendDescription.renderTarget[0].blendEnable = false;
        }

        if (blendState != null)
        {
            blendState.release();
        }
        if (device.createBlendState(blendDescription, cast blendState.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create blend state';
        }
        context.omSetBlendState(blendState, [ 1, 1, 1, 1 ], 0xffffffff);

        rendererStats.blendSwaps++;

        // Set primitive topology
        if (topology != _command.primitive)
        {
            topology = _command.primitive;
            context.iaSetPrimitiveTopology(getPrimitive(_command.primitive));
        }
    }

    /**
     * Set textures and update all cbuffers for this commands shader.
     * @param _command DrawCommand to update values from.
     */
    inline function setShaderValues(_command : DrawCommand)
    {
        var shaderResource = shaderResources.get(_command.shader.id);

        // Set all textures.
        if (shaderResource.layout.textures.length > _command.textures.length)
        {
            throw 'DirectX 11 Backend Exception : More textures required by the shader than are provided by the draw command';
        }
        else
        {
            for (i in 0...shaderResource.layout.textures.length)
            {
                var textureResource = textureResources.get(_command.textures[i].id);
                context.psSetShaderResources(i, [ textureResource.srv ]);
                context.psSetSamplers(i, [ textureResource.smp ]);

                rendererStats.textureSwaps++;
            }
        }

        // Update our default cbuffer since its values are retreived from the command and not shader class.

        var map = MappedSubResource.create();
        if (context.map(shaderResource.buffers.get(0), 0, WRITE_DISCARD, 0, map) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to map the shader matrix cbuffer';
        }

        var ptr : cpp.Pointer<cpp.Float32> = cpp.Pointer.fromRaw(map.sysMem).reinterpret();
        var itr = 0;

        for (el in (_command.projection : Float32Array))
        {
            ptr[itr++] = el;
        }
        for (el in (_command.view : Float32Array))
        {
            ptr[itr++] = el;
        }

        context.unmap(shaderResource.buffers.get(0), 0);

        var buffer = shaderResource.buffers.get(0);
        context.vsSetConstantBuffers(0, [ buffer ]);
        context.psSetConstantBuffers(0, [ buffer ]);

        // Update the user defined shader blocks.
        // Data is packed into haxe bytes then copied over.

        for (i in 0...shaderResource.layout.blocks.length)
        {
            var bytePosition = 0;
            for (val in shaderResource.layout.blocks[i].vals)
            {
                switch (ShaderType.createByName(val.type)) {
                    case Matrix4: bytePosition += writeMatrix4(shaderResource.bytes[i], bytePosition, _command.shader.uniforms.matrix4.get(val.name));
                    case Vector4: bytePosition += writeVector4(shaderResource.bytes[i], bytePosition, _command.shader.uniforms.vector4.get(val.name));
                    case Int    : bytePosition +=     writeInt(shaderResource.bytes[i], bytePosition, _command.shader.uniforms.int.get(val.name));
                }
            }

            // Map and memcpy the bytes to the subresource data.
            var map = MappedSubResource.create();
            if (context.map(shaderResource.buffers.get(i + 1), 0, WRITE_DISCARD, 0, map) != 0)
            {
                throw 'DirectX 11 Backend Exception : Failed to map shader cbuffer $i';
            }

            // TODO : Look into memcpy to simplify this code.
            var ptr : cpp.Pointer<cpp.UInt8> = cpp.Pointer.fromRaw(map.sysMem).reinterpret();
            var itr = 0;
            for (int in shaderResource.bytes[i].getData())
            {
                ptr[itr++] = int;
            }

            context.unmap(shaderResource.buffers.get(i + 1), 0);

            var buffer = shaderResource.buffers.get(i + 1);
            context.vsSetConstantBuffers(i + 1, [ buffer ]);
            context.psSetConstantBuffers(i + 1, [ buffer ]);
        }
    }

    /**
     * Write a matrix into a byte buffer.
     * @param _bytes    Bytes to write into.
     * @param _position Starting bytes offset.
     * @param _matrix   Matrix to write.
     * @return Number of bytes written.
     */
    inline function writeMatrix4(_bytes : Bytes, _position : Int, _matrix : Matrix) : Int
    {
        var idx = 0;
        for (el in (_matrix : Float32Array))
        {
            _bytes.setFloat(_position + idx, el);
            idx += 4;
        }

        return 64;
    }

    /**
     * Write a vector into a byte buffer.
     * @param _bytes    Bytes to write into.
     * @param _position Starting bytes offset.
     * @param _vector   Vector to write.
     * @return Number of bytes written.
     */
    inline function writeVector4(_bytes : Bytes, _position : Int, _vector : Vector) : Int
    {
        _bytes.setFloat(_position +  0, _vector.x);
        _bytes.setFloat(_position +  4, _vector.y);
        _bytes.setFloat(_position +  8, _vector.z);
        _bytes.setFloat(_position + 12, _vector.w);

        return 16;
    }

    /**
     * Write a 32bit integer into a byte buffer.
     * @param _bytes    Bytes to write into.
     * @param _position Starting bytes offset.
     * @param _int      Int to write.
     * @return Number of bytes written.
     */
    inline function writeInt(_bytes : Bytes, _position : Int, _int : Int) : Int
    {
        _bytes.setInt32(_position, _int);

        return 4;
    }

    /**
     * Convert our blend enum to a D3D blend enum.
     * @param _blend Blend enum.
     * @return D3D11_BLEND
     */
    inline function getBlend(_blend : BlendMode) : D3D11_BLEND
    {
        return switch (_blend) {
            case Zero             : ZERO;
            case One              : ONE;
            case SrcAlphaSaturate : SRC_ALPHA_SAT;
            case SrcColor         : SRC_COLOR;
            case OneMinusSrcColor : INV_SRC_COLOR;
            case SrcAlpha         : SRC_ALPHA;
            case OneMinusSrcAlpha : INV_SRC_ALPHA;
            case DstAlpha         : DEST_ALPHA;
            case OneMinusDstAlpha : INV_DEST_ALPHA;
            case DstColor         : DEST_COLOR;
            case OneMinusDstColor : INV_DEST_COLOR;
        }
    }

    /**
     * Convert our primitive enum to a D3D primitive enum.
     * @param _primitive Primitive enum.
     * @return D3D_PRIMITIVE_TOPOLOGY
     */
    inline function getPrimitive(_primitive : PrimitiveType) : D3D_PRIMITIVE_TOPOLOGY
    {
        return switch (_primitive) {
            case Points        : POINTLIST;
            case Lines         : LINELIST;
            case LineStrip     : LINESTRIP;
            case Triangles     : TRIANGLELIST;
            case TriangleStrip : TRIANGLESTRIP;
        }
    }
}

/**
 * Representation of the backbuffer.
 */
private class BackBuffer
{
    /**
     * Width of the backbuffer.
     */
    public var width : Int;

    /**
     * Height of the backbuffer.
     */
    public var height : Int;

    /**
     * View scale of the backbuffer.
     */
    public var viewportScale : Float;

    /**
     * Framebuffer object for the backbuffer.
     */
    public var renderTargetView : RenderTargetView;

    public function new(_width : Int, _height : Int, _viewportScale : Float)
    {
        width            = _width;
        height           = _height;
        viewportScale    = _viewportScale;
    }
}

/**
 * Holds the DirectX resources required for drawing a texture.
 */
private class DXTextureInformation
{
    /**
     * D3D11 Texture2D pointer.
     */
    public var tex : Texture2D;

    /**
     * D3D11 Shader Resource View to view the texture.
     */
    public var srv : ShaderResourceView;

    /**
     * D3D11 Sampler State to sample the textures data.
     */
    public var smp : SamplerState;

    public function new()
    {
        //
    }
}

/**
 * Holds the DirectX resources required for setting and uploading data to a shader.
 */
private class DXShaderInformation
{
    /**
     * JSON structure describing the textures and blocks in the shader.
     */
    public var layout : ShaderLayout;

    /**
     * D3D11 vertex shader pointer.
     */
    public var vertex : VertexShader;

    /**
     * D3D11 pixel shader pointer.
     */
    public var pixel : PixelShader;

    /**
     * D3D11 Vertex input description of this shader.
     */
    public var input : InputLayout;

    /**
     * Map to all D3D11 cbuffers used in this shader.
     * Array cannot be used since hxcpp doesn't like array of pointers.
     */
    public var buffers : Map<Int, Buffer>;

    /**
     * Array of all bytes for user the corresponding buffer.
     */
    public var bytes : Array<Bytes>;

    public function new()
    {
        //
    }
}

/**
 * Holds the DirectX resources required for setting the render target.
 */
private class DXTargetInformation
{
    /**
     * D3D11 Texture2D which will old the framebuffer data.
     */
    public var tex : Texture2D;

    /**
     * D3D11 Shader Resource View for the texture so the render texture can be drawn to the screen.
     */
    public var srv : ShaderResourceView;

    /**
     * D3D11 Sampler State to sample the textures data. 
     */
    public var smp : SamplerState;

    /**
     * D3D11 Render Target View to set this texture as the render target.
     */
    public var rtv : RenderTargetView;

    public function new()
    {
        //
    }
}

/**
 * Stores the range of a draw command.
 */
private class DrawCommandRange
{
    /**
     * The number of vertices in this draw command.
     */
    public final vertices : Int;

    /**
     * The number of vertices this command is offset into the current range.
     */
    public final vertexOffset : Int;

    /**
     * The number of indices in this draw command.
     */
    public final indices : Int;

    /**
     * The number of bytes this command is offset into the current range.
     */
    public final indexOffset : Int;

    inline public function new(_vertices : Int, _vertexOffset : Int, _indices : Int, _indexOffset)
    {
        vertices     = _vertices;
        vertexOffset = _vertexOffset;
        indices      = _indices;
        indexOffset  = _indexOffset;
    }
}
