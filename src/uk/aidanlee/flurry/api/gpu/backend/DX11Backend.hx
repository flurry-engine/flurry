package uk.aidanlee.flurry.api.gpu.backend;

import haxe.io.Bytes;
import haxe.ds.Map;
import cpp.Float32;
import cpp.Int32;
import cpp.UInt8;
import cpp.UInt16;
import cpp.Pointer;
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
import d3d11.resources.DepthStencilViewDescription;
import d3d11.resources.DepthStencilView;
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
import d3d11.DepthStencilDescription;
import d3d11.DepthStencilState;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher.StencilFunction;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher.ComparisonFunction;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.Resource.ShaderType;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.thread.JobQueue;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.utils.BytesPacker;

using Safety;
using cpp.NativeArray;
using cpp.Native;

@:headerCode('
#include <comdef.h>
#include <D3Dcompiler.h>
#include "SDL_syswm.h"
')
class DX11Backend implements IRendererBackend
{
    static final RENDERER_THREADS = #if flurry_dx11_no_multithreading 1 #else Std.int(Maths.max(SDL.getCPUCount() - 2, 1)) #end;

    /**
     * Signals for when shaders and images are created and removed.
     */
    final resourceEvents : ResourceEvents;

    /**
     * Signals for when a window change has been requested and dispatching back the result.
     */
    final displayEvents : DisplayEvents;

    /**
     * Access to the renderer which owns this backend.
     */
    final rendererStats : RendererStats;

    /**
     * Constant vector instance which is used to transform vertices when copying into the vertex buffer.
     */
    final transformationVectors : Array<Vector>;

    /**
     * Queue for running functions on another thread.
     */
    final jobQueue : JobQueue;

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
     * Texture used for the depth buffer.
     */
    var depthBufferTexture : Texture2D;

    /**
     * Depth and stencil description.
     */
    var depthStencilDescription : DepthStencilDescription;

    /**
     * Depth and stencil state.
     */
    var depthStencilState : DepthStencilState;

    /**
     * Depth and stencil view state.
     */
    var depthStencilViewDescription : DepthStencilViewDescription;

    /**
     * Depth and stencil resource view.
     */
    var depthStencilView : DepthStencilView;

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

    // SDL Window

    var window : Window;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _rendererStats : RendererStats, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        resourceEvents = _resourceEvents;
        displayEvents  = _displayEvents;
        rendererStats  = _rendererStats;

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

        shaderResources  = [];
        textureResources = [];
        targetResources  = [];

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

        var depthTextureDesc = Texture2DDescription.create();
        depthTextureDesc.width = _windowConfig.width;
        depthTextureDesc.height = _windowConfig.height;
        depthTextureDesc.mipLevels = 1;
        depthTextureDesc.arraySize = 1;
        depthTextureDesc.format = D32_FLOAT_S8X24_UINT;
        depthTextureDesc.sampleDesc.count = 1;
        depthTextureDesc.sampleDesc.quality = 0;
        depthTextureDesc.usage = DEFAULT;
        depthTextureDesc.bindFlags = DEPTH_STENCIL;
        depthTextureDesc.cpuAccessFlags = 0;
        depthTextureDesc.miscFlags = 0;

        if (device.createTexture2D(cast depthTextureDesc.addressOf(), null, cast depthBufferTexture.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create depth buffer texture';
        }

        depthStencilViewDescription = DepthStencilViewDescription.create();
        depthStencilViewDescription.format = D32_FLOAT_S8X24_UINT;
        depthStencilViewDescription.viewDimension = DSV_DIMENSION_TEXTURE2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        if (device.createDepthStencilView(cast depthBufferTexture, cast depthStencilViewDescription.addressOf(), cast depthStencilView.addressOf()) != 0)
        {
            throw 'DirectX 11 Backend Exception : Failed to create depth stencil view';
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
        context.omSetRenderTargets([ backbuffer.renderTargetView ], depthStencilView);

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;

        dynamicCommandRanges  = new Map();
        transformationVectors = [ for (i in 0...RENDERER_THREADS) new Vector() ];
        jobQueue              = new JobQueue(RENDERER_THREADS);

        // Setup initial state tracker
        viewport = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        scissor  = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        topology = PrimitiveType.Triangles;
        target   = null;
        shader   = null;
        texture  = null;

        resourceEvents.created.add(onResourceCreated);
        resourceEvents.removed.add(onResourceRemoved);
    }

    public function clear()
    {
        context.clearRenderTargetView(backbuffer.renderTargetView, [ 0.2, 0.2, 0.2, 1.0 ]);
        context.clearDepthStencilView(depthStencilView, untyped __cpp__('D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL'), 1, 0);
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
        var vtxDst : Pointer<Float32> = Pointer.fromRaw(mappedVtxBuffer.sysMem).reinterpret();
        var idxDst : Pointer<UInt16>  = Pointer.fromRaw(mappedIdxBuffer.sysMem).reinterpret();

        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, command.indices, indexOffset));

            var split     = Maths.floor(command.geometry.length / RENDERER_THREADS);
            var remainder = command.geometry.length % RENDERER_THREADS;
            var range     = command.geometry.length < RENDERER_THREADS ? command.geometry.length : RENDERER_THREADS;
            for (i in 0...range)
            {
                var geomStartIdx   = split * i;
                var geomEndIdx     = geomStartIdx + (i != range - 1 ? split : split + remainder);
                var idxValueOffset = 0;
                var idxWriteOffset = indexOffset;
                var vtxWriteOffset = vertexFloatOffset;

                for (j in 0...geomStartIdx)
                {
                    idxValueOffset += command.geometry[j].vertices.length;
                    idxWriteOffset += command.geometry[j].indices.length;
                    vtxWriteOffset += command.geometry[j].vertices.length * 9;
                }

                jobQueue.queue(() -> {
                    for (j in geomStartIdx...geomEndIdx)
                    {
                        for (index in command.geometry[j].indices)
                        {
                            idxDst[idxWriteOffset++] = idxValueOffset + index;
                        }

                        for (vertex in command.geometry[j].vertices)
                        {
                            // Copy the vertex into another vertex.
                            // This allows us to apply the transformation without permanently modifying the original geometry.
                            transformationVectors[i].copyFrom(vertex.position);
                            transformationVectors[i].transform(command.geometry[j].transformation.transformation);

                            vtxDst[vtxWriteOffset++] = transformationVectors[i].x;
                            vtxDst[vtxWriteOffset++] = transformationVectors[i].y;
                            vtxDst[vtxWriteOffset++] = transformationVectors[i].z;
                            vtxDst[vtxWriteOffset++] = vertex.color.r;
                            vtxDst[vtxWriteOffset++] = vertex.color.g;
                            vtxDst[vtxWriteOffset++] = vertex.color.b;
                            vtxDst[vtxWriteOffset++] = vertex.color.a;
                            vtxDst[vtxWriteOffset++] = vertex.texCoord.x;
                            vtxDst[vtxWriteOffset++] = vertex.texCoord.y;
                        }

                        idxValueOffset += command.geometry[j].vertices.length;
                    }
                });
            }

            for (geom in command.geometry)
            {
                vertexFloatOffset += geom.vertices.length * 9;
                indexOffset       += geom.indices.length;
                vertexOffset      += geom.vertices.length;
            }

            jobQueue.wait();
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
        var vtx : Pointer<Float32> = Pointer.fromRaw(mappedVtxBuffer.sysMem).reinterpret();
        var idx : Pointer<UInt16>  = Pointer.fromRaw(mappedIdxBuffer.sysMem).reinterpret();

        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, command.indices, indexOffset));

            for (i in command.vtxStartIndex...command.vtxEndIndex)
            {
                vtx[vertexFloatOffset++] = command.vtxData[i];
            }

            for (i in command.idxStartIndex...command.idxEndIndex)
            {
                idx[indexOffset++] = command.idxData[i];
            }

            vertexOffset += command.vertices;
        }

        context.unmap(vertexBuffer, 0);
        context.unmap(indexBuffer, 0);
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
        context.omSetRenderTargets([ backbuffer.renderTargetView ], depthStencilView);
        target = null;

        rendererStats.targetSwaps++;
    }

    /**
     * Release all DX11 interface pointers.
     */
    public function cleanup()
    {
        resourceEvents.created.remove(onResourceCreated);
        resourceEvents.removed.remove(onResourceRemoved);

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

        // Create our shader and a class to store its resources.
        var resource = new DXShaderInformation();
        resource.layout = _resource.layout;
        resource.vertex = vertexShader;
        resource.pixel  = pixelShader;
        resource.input  = inputLayout;

        for (i in 0..._resource.layout.blocks.length)
        {
            var blockBytes       = BytesPacker.allocateBytes(Dx11, _resource.layout.blocks[i].vals);
            var blockDescription = BufferDescription.create();
            blockDescription.byteWidth      = blockBytes.length;
            blockDescription.usage          = DYNAMIC;
            blockDescription.bindFlags      = CONSTANT_BUFFER;
            blockDescription.cpuAccessFlags = WRITE;

            var block : Buffer = null;
            if (device.createBuffer(cast blockDescription.addressOf(), null, cast block.addressOf()) != 0)
            {
                throw 'DirectX 11 Backend Exception : ${_resource.id} : Failed to create cbuffer for block ${_resource.layout.blocks[i].name}';
            }

            resource.buffers.set(i, block);
            resource.bytes.set(i, blockBytes);
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
        imgDesc.format    = B8G8R8A8_UNORM;
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
        depthStencilDescription.depthEnable    = _command.depth.depthTesting;
        depthStencilDescription.depthWriteMask = _command.depth.depthMasking ? DEPTH_WRITE_MASK_ALL : DEPTH_WRITE_MASK_ZERO;
        depthStencilDescription.depthFunc      = getComparisonFunction(_command.depth.depthFunction);

        depthStencilDescription.stencilEnable    = _command.stencil.stencilTesting;
        depthStencilDescription.stencilReadMask  = _command.stencil.stencilFrontMask;
        depthStencilDescription.stencilWriteMask = _command.stencil.stencilBackMask;

        depthStencilDescription.frontFace.stencilFailOp      = getStencilOp(_command.stencil.stencilFrontTestFail);
        depthStencilDescription.frontFace.stencilDepthFailOp = getStencilOp(_command.stencil.stencilFrontDepthTestFail);
        depthStencilDescription.frontFace.stencilPassOp      = getStencilOp(_command.stencil.stencilFrontDepthTestPass);
        depthStencilDescription.frontFace.stencilFunc        = getComparisonFunction(_command.stencil.stencilFrontFunction);

        depthStencilDescription.backFace.stencilFailOp      = getStencilOp(_command.stencil.stencilBackTestFail);
        depthStencilDescription.backFace.stencilDepthFailOp = getStencilOp(_command.stencil.stencilBackDepthTestFail);
        depthStencilDescription.backFace.stencilPassOp      = getStencilOp(_command.stencil.stencilBackDepthTestPass);
        depthStencilDescription.backFace.stencilFunc        = getComparisonFunction(_command.stencil.stencilBackFunction);

        if (device.createDepthStencilState(depthStencilDescription.addressOf(), cast depthStencilState.addressOf()) != 0)
        {
            throw 'Failed to create depth stencil state';
        }

        context.omSetDepthStencilState(depthStencilState, 1);

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
            context.omSetRenderTargets([ renderTarget ], depthStencilView);

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
        var preferedUniforms = _command.uniforms.or(_command.shader.uniforms);

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

        // Update the user defined shader blocks.
        // Data is packed into haxe bytes then copied over.

        for (i in 0...shaderResource.layout.blocks.length)
        {
            var map = MappedSubResource.create();
            if (context.map(shaderResource.buffers[i], 0, WRITE_DISCARD, 0, map) != 0)
            {
                throw 'DirectX 11 Backend Exception : Failed to map shader cbuffer ${shaderResource.layout.blocks[i].name}';
            }

            var ptr : Pointer<UInt8> = Pointer.fromRaw(map.sysMem).reinterpret();

            if (shaderResource.layout.blocks[i].name == 'defaultMatrices')
            {
                cpp.Stdlib.memcpy(ptr          , (_command.projection : Float32Array).view.buffer.getData().address(0), 64);
                cpp.Stdlib.memcpy(ptr.incBy(64), (_command.view       : Float32Array).view.buffer.getData().address(0), 64);
            }
            else
            {
                // Otherwise upload all user specified uniform values.
                // TODO : We should have some sort of error checking if the expected uniforms are not found.
                for (val in shaderResource.layout.blocks[i].vals)
                {
                    var pos = BytesPacker.getPosition(Dx11, shaderResource.layout.blocks[i].vals, val.name);

                    switch (ShaderType.createByName(val.type))
                    {
                        case Matrix4:
                            var mat = preferedUniforms.matrix4.exists(val.name) ? preferedUniforms.matrix4.get(val.name) : _command.shader.uniforms.matrix4.get(val.name);
                            cpp.Stdlib.memcpy(ptr.incBy(pos), (mat : Float32Array).view.buffer.getData().address(0), 64);
                        case Vector4:
                            var vec = preferedUniforms.vector4.exists(val.name) ? preferedUniforms.vector4.get(val.name) : _command.shader.uniforms.vector4.get(val.name);
                            cpp.Stdlib.memcpy(ptr.incBy(pos), (vec : Float32Array).view.buffer.getData().address(0), 16);
                        case Int:
                            var dst : Pointer<Int32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), preferedUniforms.int.exists(val.name) ? preferedUniforms.int.get(val.name) : _command.shader.uniforms.int.get(val.name));
                        case Float:
                            var dst : Pointer<Float32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), preferedUniforms.float.exists(val.name) ? preferedUniforms.float.get(val.name) : _command.shader.uniforms.float.get(val.name));
                    }
                }
            }

            context.unmap(shaderResource.buffers[i], 0);

            var buffer = shaderResource.buffers.get(i);
            context.vsSetConstantBuffers(i, [ buffer ]);
            context.psSetConstantBuffers(i, [ buffer ]);
        }
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

    inline function getComparisonFunction(_function : ComparisonFunction) : D3D11_COMPARISON_FUNC
    {
        return switch (_function)
        {
            case Always             : ALWAYS;
            case Never              : NEVER;
            case Equal              : EQUAL;
            case LessThan           : LESS;
            case LessThanOrEqual    : LESS_EQUAL;
            case GreaterThan        : GREATER;
            case GreaterThanOrEqual : GREATER_EQUAL;
            case NotEqual           : NOT_EQUAL;
        }
    }

    inline function getStencilOp(_stencil : StencilFunction) : D3D11_STENCIL_OP
    {
        return switch (_stencil)
        {
            case Keep: STENCIL_OP_KEEP;
            case Zero: STENCIL_OP_ZERO;
            case Replace: STENCIL_OP_REPLACE;
            case Invert: STENCIL_OP_INVERT;
            case Increment: STENCIL_OP_INCR_SAT;
            case IncrementWrap: STENCIL_OP_INCR;
            case Decrement: STENCIL_OP_DECR_SAT;
            case DecrementWrap: STENCIL_OP_DECR;
        }
    }

    function printHRESULT(_hresult : Int)
    {
        untyped __cpp__('_com_error err({0})', _hresult);
        untyped __cpp__('printf(err.ErrorMessage())');
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
    public final buffers : Map<Int, Buffer>;

    /**
     * Array of all bytes for user the corresponding buffer.
     */
    public final bytes : Map<Int, Bytes>;

    public function new()
    {
        buffers = [];
        bytes   = [];
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
