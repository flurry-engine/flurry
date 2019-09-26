package uk.aidanlee.flurry.api.gpu.backend;

import haxe.Exception;
import haxe.io.Bytes;
import cpp.Float32;
import cpp.Int32;
import cpp.UInt8;
import cpp.UInt16;
import cpp.Pointer;
import cpp.Stdlib.memcpy;
import sdl.Window;
import sdl.SDL;
import dxgi.Dxgi;
import dxgi.structures.DxgiSwapChainDescription;
import dxgi.interfaces.DxgiOutput;
import dxgi.interfaces.DxgiAdapter;
import dxgi.interfaces.DxgiFactory;
import dxgi.interfaces.DxgiSwapChain;
import d3dcompiler.D3dCompiler;
import d3dcommon.interfaces.D3dBlob;
import d3d11.D3d11;
import d3d11.enumerations.D3d11CreateDeviceFlags;
import d3d11.enumerations.D3d11PrimitiveTopology;
import d3d11.enumerations.D3d11ClearFlag;
import d3d11.enumerations.D3d11StencilOp;
import d3d11.enumerations.D3d11ComparisonFunction;
import d3d11.enumerations.D3d11Blend;
import d3d11.enumerations.D3d11CpuAccessFlag;
import d3d11.enumerations.D3d11BindFlag;
import d3d11.enumerations.D3d11ColorWriteEnable;
import d3d11.enumerations.D3d11TextureAddressMode;
import d3d11.enumerations.D3d11Filter;
import d3d11.structures.D3d11DepthStencilDescription;
import d3d11.structures.D3d11SamplerDescription;
import d3d11.structures.D3d11InputElementDescription;
import d3d11.structures.D3d11SubResourceData;
import d3d11.structures.D3d11BufferDescription;
import d3d11.structures.D3d11MappedSubResource;
import d3d11.structures.D3d11DepthStencilViewDescription;
import d3d11.structures.D3d11Texture2DDescription;
import d3d11.structures.D3d11RasterizerDescription;
import d3d11.structures.D3d11BlendDescription;
import d3d11.structures.D3d11Rect;
import d3d11.structures.D3d11Viewport;
import d3d11.interfaces.D3d11InputLayout;
import d3d11.interfaces.D3d11PixelShader;
import d3d11.interfaces.D3d11VertexShader;
import d3d11.interfaces.D3d11DepthStencilState;
import d3d11.interfaces.D3d11SamplerState;
import d3d11.interfaces.D3d11ShaderResourceView;
import d3d11.interfaces.D3d11RenderTargetView;
import d3d11.interfaces.D3d11DepthStencilView;
import d3d11.interfaces.D3d11Texture2D;
import d3d11.interfaces.D3d11RasterizerState;
import d3d11.interfaces.D3d11BlendState;
import d3d11.interfaces.D3d11Buffer;
import d3d11.interfaces.D3d11DeviceContext;
import d3d11.interfaces.D3d11Device;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.gpu.StencilFunction;
import uk.aidanlee.flurry.api.gpu.ComparisonFunction;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.BlendMode;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.camera.Camera3D;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.EdgeClamping;
import uk.aidanlee.flurry.api.gpu.textures.Filtering;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.thread.JobQueue;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.utils.bytes.BytesPacker;
import uk.aidanlee.flurry.utils.bytes.FastFloat32Array;

using Safety;
using cpp.NativeArray;

@:headerCode('#include <D3Dcompiler.h>
#include "SDL_syswm.h"')
@:buildXml('<target id = "haxe">
    <lib name = "dxgi.lib"        if = "windows" unless = "static_link" />
    <lib name = "d3d11.lib"       if = "windows" unless = "static_link" />
    <lib name = "d3dcompiler.lib" if = "windows" unless = "static_link" />
</target>')
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
     * D3D11 device for this window.
     */
    final device : D3d11Device;

    /**
     * Main D3D11 context for this windows device.
     */
    final context : D3d11DeviceContext;

    /**
     * DXGI swapchain for presenting the backbuffer to the window.
     */
    final swapchain : DxgiSwapChain;

    /**
     * Single main vertex buffer.
     */
    final vertexBuffer : D3d11Buffer;

    /**
     * Single main index buffer.
     */
    final indexBuffer : D3d11Buffer;

    /**
     * Native D3D viewport struct.
     */
    final nativeView : D3d11Viewport;

    /**
     * Native D3D scissor clip struct.
     */
    final nativeClip : D3d11Rect;

    /**
     * Native D3D blend description struct.
     */
    final blendDescription : D3d11BlendDescription;

    /**
     * Native D3D blend state interface.
     */
    final blendState : D3d11BlendState;

    /**
     * Native D3D raster state interface.
     */
    final rasterState : D3d11RasterizerState;

    /**
     * Depth and stencil state.
     */
    final depthStencilState : D3d11DepthStencilState;

    /**
     * Description of the depth and stencil state.
     */
    final depthStencilDescription : D3d11DepthStencilDescription;

    /**
     * Depth and stencil resource view.
     */
    final depthStencilView : D3d11DepthStencilView;

    /**
     * The texture used for the dxgi swapchain.
     */
    final swapchainTexture : D3d11Texture2D;

    /**
     * The texture used for the depth and stencil view.
     */
    final depthStencilTexture : D3d11Texture2D;

    /**
     * D3D11 resource used for mapping the vertex buffer.
     */
    final mappedVertexBuffer : D3d11MappedSubResource;

    /**
     * D3D11 resource used for mapping the index buffer.
     */
    final mappedIndexBuffer : D3d11MappedSubResource;

    /**
     * D3D11 resource used for mapping constant buffers.
     */
    final mappedUniformBuffer : D3d11MappedSubResource;

    /**
     * Representation of the backbuffer.
     * Used as a default render target.
     */
    final backbuffer : BackBuffer;

    /**
     * Normalised RGBA colour to clear the backbuffer with each frame.
     */
    final clearColour : Array<Float>;

    /**
     * dummy identity matrix for passing into shaders so they have parity with OGL4 shaders.
     */
    final dummyModelMatrix : Matrix;

    /**
     * All the resource views which will be bound for the shader.
     */
    final shaderTextureResources : Array<Null<D3d11ShaderResourceView>>;

    /**
     * All the samplers which will be bound for the shader.
     */
    final shaderTextureSamplers : Array<Null<D3d11SamplerState>>;

    /**
     * Map of shader name to the D3D11 resources required to use the shader.
     */
    final shaderResources : Map<String, ShaderInformation>;

    /**
     * Map of texture name to the D3D11 resources required to use the texture.
     */
    final textureResources : Map<String, TextureInformation>;

    /**
     * Sampler to use when none is provided.
     */
    final defaultSampler : D3d11SamplerState;

    /**
     * Map of command IDs and the vertex offset into the buffer.
     */
    final commandVtxOffsets : Map<Int, Int>;

    /**
     * Map of command IDs and the index offset into the buffer.
     */
    final commandIdxOffsets : Map<Int, Int>;

    /**
     * Map of all the model matices to transform buffer commands.
     */
    final bufferModelMatrix : Map<Int, Matrix>;

    /**
     * Rectangle used to hold the clip coordinates of the command currently being processed.
     */
    final cmdClip : Rectangle;

    /**
     * Rectangle used to hold the viewport coordinates of the command currently being processed.
     */
    final cmdViewport : Rectangle;

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
            throw new Exception('Unable to get DXGI information for the main SDL window');
        }

        shaderResources  = [];
        textureResources = [];
        shaderTextureResources = [ for (i in 0...16) null ];
        shaderTextureSamplers  = [ for (i in 0...16) null ];

        // Persistent D3D11 objects and descriptions
        swapchain               = new DxgiSwapChain();
        swapchainTexture        = new D3d11Texture2D();
        device                  = new D3d11Device();
        context                 = new D3d11DeviceContext();
        depthStencilView        = new D3d11DepthStencilView();
        depthStencilState       = new D3d11DepthStencilState();
        depthStencilTexture     = new D3d11Texture2D();
        blendState              = new D3d11BlendState();
        rasterState             = new D3d11RasterizerState();
        mappedVertexBuffer      = new D3d11MappedSubResource();
        mappedIndexBuffer       = new D3d11MappedSubResource();
        mappedUniformBuffer     = new D3d11MappedSubResource();
        vertexBuffer            = new D3d11Buffer();
        indexBuffer             = new D3d11Buffer();
        depthStencilDescription = new D3d11DepthStencilDescription();

        // Setup the DXGI factory and get this windows adapter and output.
        var factory = new DxgiFactory();
        var adapter = new DxgiAdapter();
        var output  = new DxgiOutput();

        if (Dxgi.createFactory(factory) != Ok)
        {
            throw new Exception('DXGI Failure creating factory');
        }
        if (factory.enumAdapters(adapterIdx, adapter) != Ok)
        {
            throw new Exception('DXGI Failure enumerating adapter $adapterIdx');
        }
        if (adapter.enumOutputs(outputIdx, output) != Ok)
        {
            throw new Exception('DXGI Failure enumerating output $outputIdx');
        }

        // Create the device, context, and swapchain.
        var description = new DxgiSwapChainDescription();
        description.bufferDesc.width  = _windowConfig.width;
        description.bufferDesc.height = _windowConfig.height;
        description.bufferDesc.format = R8G8B8A8UNorm;
        description.sampleDesc.count  = 1;
        description.outputWindow      = hwnd;
        description.bufferCount       = 1;
        description.bufferUsage       = RenderTargetOutput;
        description.windowed          = true;

        var deviceCreationFlags = D3d11CreateDeviceFlags.SingleThreaded;

        // Create our actual device and swapchain
        if (D3d11.createDevice(adapter, Unknown, null, deviceCreationFlags, null, D3d11.SdkVersion, device, null, context) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Device');
        }
        if (factory.createSwapChain(device, description, swapchain) != 0)
        {
            throw new Dx11ResourceCreationException('IDXGISwapChain');
        }

        // Create the backbuffer render target.
        backbuffer = new BackBuffer(_windowConfig.width, _windowConfig.height, 1);

        if (swapchain.getBuffer(0, NativeID3D11Texture2D.uuid(), swapchainTexture) != Ok)
        {
            throw new DX11FetchBackbufferException();
        }
        if (device.createRenderTargetView(swapchainTexture, null, backbuffer.renderTargetView) != 0)
        {
            throw new Dx11ResourceCreationException('ID3D11RenderTargetView');
        }

        // Create the default viewport
        nativeView = new D3d11Viewport();
        nativeView.topLeftX = 0;
        nativeView.topLeftY = 0;
        nativeView.width    = _windowConfig.width;
        nativeView.height   = _windowConfig.height;
        nativeView.minDepth = 0;
        nativeView.maxDepth = 1;

        // Create the default clip
        nativeClip = new D3d11Rect();
        nativeClip.top    = 0;
        nativeClip.left   = 0;
        nativeClip.right  = _windowConfig.width;
        nativeClip.bottom = _windowConfig.height;

        // Setup the rasterizer state.
        var rasterDescription = new D3d11RasterizerDescription();
        rasterDescription.fillMode              = Solid;
        rasterDescription.cullMode              = None;
        rasterDescription.frontCounterClockwise = false;
        rasterDescription.depthBias             = 0;
        rasterDescription.slopeScaledDepthBias  = 0;
        rasterDescription.depthBiasClamp        = 0;
        rasterDescription.depthClipEnable       = true;
        rasterDescription.scissorEnable         = true;
        rasterDescription.multisampleEnable     = false;
        rasterDescription.antialiasedLineEnable = false;

        if (device.createRasterizerState(rasterDescription, rasterState) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11RasterizerState');
        }

        // Setup the initial blend state
        blendDescription = new D3d11BlendDescription();
        blendDescription.alphaToCoverageEnable  = false;
        blendDescription.independentBlendEnable = false;
        blendDescription.renderTarget[0].blendEnable    = true;
        blendDescription.renderTarget[0].srcBlend       = SourceAlpha;
        blendDescription.renderTarget[0].srcBlendAlpha  = One;
        blendDescription.renderTarget[0].destBlend      = InverseSourceAlpha;
        blendDescription.renderTarget[0].destBlendAlpha = Zero;
        blendDescription.renderTarget[0].blendOp        = Add;
        blendDescription.renderTarget[0].blendOpAlpha   = Add;
        blendDescription.renderTarget[0].renderTargetWriteMask = D3d11ColorWriteEnable.All;

        if (device.createBlendState(blendDescription, blendState) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11BlendState');
        }

        // Create our (initially) empty vertex buffer.
        var bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = (_rendererConfig.dynamicVertices + _rendererConfig.unchangingVertices) * 9;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = D3d11BindFlag.VertexBuffer;
        bufferDesc.cpuAccessFlags = D3d11CpuAccessFlag.Write;

        if (device.createBuffer(bufferDesc, null, vertexBuffer) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Buffer');
        }

        var bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = (_rendererConfig.dynamicIndices + _rendererConfig.unchangingIndices) * 2;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = D3d11BindFlag.IndexBuffer;
        bufferDesc.cpuAccessFlags = D3d11CpuAccessFlag.Write;

        if (device.createBuffer(bufferDesc, null, indexBuffer) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Buffer');
        }

        var depthTextureDesc = new D3d11Texture2DDescription();
        depthTextureDesc.width              = _windowConfig.width;
        depthTextureDesc.height             = _windowConfig.height;
        depthTextureDesc.mipLevels          = 1;
        depthTextureDesc.arraySize          = 1;
        depthTextureDesc.format             = D32FloatS8X24UInt;
        depthTextureDesc.sampleDesc.count   = 1;
        depthTextureDesc.sampleDesc.quality = 0;
        depthTextureDesc.usage              = Default;
        depthTextureDesc.bindFlags          = DepthStencil;
        depthTextureDesc.cpuAccessFlags     = 0;
        depthTextureDesc.miscFlags          = 0;

        if (device.createTexture2D(depthTextureDesc, null, depthStencilTexture) != 0)
        {
            throw new Dx11ResourceCreationException('ID3D11Texture2D');
        }

        var depthStencilViewDescription = new D3d11DepthStencilViewDescription();
        depthStencilViewDescription.format             = D32FloatS8X24UInt;
        depthStencilViewDescription.viewDimension      = Texture2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        if (device.createDepthStencilView(depthStencilTexture, depthStencilViewDescription, depthStencilView) != 0)
        {
            throw new Dx11ResourceCreationException('ID3D11DepthStencilView');
        }

        // Create the default texture sampler
        var samplerDescription = new D3d11SamplerDescription();
        samplerDescription.filter         = MinMagMipPoint;
        samplerDescription.addressU       = Clamp;
        samplerDescription.addressV       = Clamp;
        samplerDescription.addressW       = Clamp;
        samplerDescription.mipLodBias     = 0;
        samplerDescription.maxAnisotropy  = 1;
        samplerDescription.comparisonFunc = Never;
        samplerDescription.borderColor[0] = 1;
        samplerDescription.borderColor[1] = 1;
        samplerDescription.borderColor[2] = 1;
        samplerDescription.borderColor[3] = 1;
        samplerDescription.minLod         = -1;
        samplerDescription.minLod         = 1;

        defaultSampler = new D3d11SamplerState();
        if (device.createSamplerState(samplerDescription, defaultSampler) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11SamplerState');
        }

        // Set the initial context state.
        var stride = (9 * 4);
        var offset = 0;
        context.iaSetIndexBuffer(indexBuffer, R16UInt, offset);
        context.iaSetVertexBuffers(0, [ vertexBuffer ], [ stride ], [ offset ]);
        context.iaSetPrimitiveTopology(TriangleList);
        context.rsSetViewports([ nativeView ]);
        context.rsSetScissorRects([ nativeClip ]);
        context.rsSetState(rasterState);
        context.omSetRenderTargets([ backbuffer.renderTargetView ], depthStencilView);

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;

        commandVtxOffsets     = [];
        commandIdxOffsets     = [];
        bufferModelMatrix     = [];
        transformationVectors = [ for (i in 0...RENDERER_THREADS) new Vector() ];
        clearColour           = [ _rendererConfig.clearColour.r, _rendererConfig.clearColour.g, _rendererConfig.clearColour.b, _rendererConfig.clearColour.a ];
        jobQueue              = new JobQueue(RENDERER_THREADS);
        dummyModelMatrix      = new Matrix();

        cmdClip     = new Rectangle();
        cmdViewport = new Rectangle();

        // Setup initial state tracker
        viewport = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        scissor  = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        topology = Triangles;
        target   = null;
        shader   = null;
        texture  = null;

        resourceEvents.created.add(onResourceCreated);
        resourceEvents.removed.add(onResourceRemoved);
        displayEvents.sizeChanged.add(onSizeChanged);
        displayEvents.changeRequested.add(onSizeChangeRequest);
    }

    public function preDraw()
    {
        context.clearRenderTargetView(backbuffer.renderTargetView, clearColour);
        context.clearDepthStencilView(depthStencilView, D3d11ClearFlag.Depth | D3d11ClearFlag.Stencil, 1, 0);

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;
        commandVtxOffsets.clear();
        commandIdxOffsets.clear();
        bufferModelMatrix.clear();
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void
    {
        // Map the buffer.
        if (context.map(vertexBuffer, 0, WriteDiscard, 0, mappedVertexBuffer) != 0)
        {
            throw new DX11MappingBufferException('Vertex Buffer');
        }

        if (context.map(indexBuffer, 0, WriteDiscard, 0, mappedIndexBuffer) != 0)
        {
            throw new DX11MappingBufferException('Index Buffer');
        }

        // Get a buffer to float32s so we can copy our float32array over.
        var vtxDst : Pointer<Float32> = mappedVertexBuffer.data.reinterpret();
        var idxDst : Pointer<UInt16>  = mappedIndexBuffer.data.reinterpret();

        for (command in _commands)
        {
            commandVtxOffsets.set(command.id, vertexOffset);
            commandIdxOffsets.set(command.id, indexOffset);

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
                            transformationVectors[i].transform(command.geometry[j].transformation.world.matrix);

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
        if (context.map(vertexBuffer, 0, WriteDiscard, 0, mappedVertexBuffer) != 0)
        {
            throw new DX11MappingBufferException('Vertex Buffer');
        }

        if (context.map(indexBuffer, 0, WriteDiscard, 0, mappedIndexBuffer) != 0)
        {
            throw new DX11MappingBufferException('Index Buffer');
        }

        // Get a buffer to float32s so we can copy our float32array over.
        var idxDst : Pointer<UInt16>  = mappedIndexBuffer.data.reinterpret();
        var vtxDst : Pointer<Float32> = mappedVertexBuffer.data.reinterpret();

        idxDst.incBy(indexOffset);
        vtxDst.incBy(vertexOffset * 9);

        for (command in _commands)
        {
            commandIdxOffsets.set(command.id, indexOffset);
            commandVtxOffsets.set(command.id, vertexOffset);
            bufferModelMatrix.set(command.id, command.model);

            memcpy(
                idxDst,
                Pointer.arrayElem(command.idxData.view.buffer.getData(), command.idxStartIndex * 2),
                command.indices * 2);
            memcpy(
                vtxDst,
                Pointer.arrayElem(command.vtxData.view.buffer.getData(), command.vtxStartIndex * 9 * 4),
                command.vertices * 9 * 4);

            indexOffset       += command.indices;
            vertexOffset      += command.vertices;
            vertexFloatOffset += command.vertices * 9;

            idxDst.incBy(command.indices);
            vtxDst.incBy(command.vertices * 9);
        }

        context.unmap(indexBuffer, 0);
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
            var idxOffset = commandIdxOffsets.get(command.id);
            var vtxOffset = commandVtxOffsets.get(command.id);

            // Set context state
            setState(command);

            // Draw
            if (command.indices > 0)
            {               
                context.drawIndexed(command.indices, idxOffset, vtxOffset);
            }
            else
            {
                context.draw(command.vertices, vtxOffset);
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
        swapchain.present(Discard, 0);
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

        context.omSetRenderTargets(null, null);

        backbuffer.renderTargetView.release();
        swapchainTexture.release();

        if (swapchain.resizeBuffers(0, _width, _height, Unknown, 0) != Ok)
        {
            throw new DX11ResizeBackbufferException();
        }
        if (swapchain.getBuffer(0, NativeID3D11Texture2D.uuid(), swapchainTexture) != Ok)
        {
            throw new DX11FetchBackbufferException();
        }
        if (device.createRenderTargetView(swapchainTexture, null, backbuffer.renderTargetView) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11RenderTargetView');
        }

        // If we don't force a render target change here then the previous backbuffer pointer might still be bound and used.
        // This would cause nothing to render since that old backbuffer has now been released.
        context.omSetRenderTargets([ backbuffer.renderTargetView ], depthStencilView);
        target = null;

        // Set the scissor to the new width and height.
        // This is needed to force a clip change so it doesn't stay with the old backbuffer size.
        scissor.set(0, 0, _width, _height);

        rendererStats.targetSwaps++;
    }

    /**
     * Release all DX11 interface pointers.
     */
    public function cleanup()
    {
        resourceEvents.created.remove(onResourceCreated);
        resourceEvents.removed.remove(onResourceRemoved);
        displayEvents.sizeChanged.remove(onSizeChanged);
        displayEvents.changeRequested.remove(onSizeChangeRequest);

        SDL.destroyWindow(window);
    }

    // #region SDL Window Management

    function createWindow(_options : FlurryWindowConfig)
    {        
        window = SDL.createWindow('Flurry', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
    }

    // #endregion

    // #region resource handling

    function onResourceCreated(_resource : Resource)
    {
        switch _resource.type
        {
            case Image  : createTexture(cast _resource);
            case Shader : createShader(cast _resource);
            case _:
        }
    }

    function onResourceRemoved(_resource : Resource)
    {
        switch _resource.type
        {
            case Image  : removeTexture(cast _resource);
            case Shader : removeShader(cast _resource);
            case _:
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
        if (shaderResources.exists(_resource.id))
        {
            return;
        }

        if (_resource.hlsl == null)
        {
            throw new DX11NoShaderSourceException(_resource.id);
        }

        var vertexBytecode = new D3dBlob();
        var pixelBytecode  = new D3dBlob();

        if (_resource.hlsl.compiled)
        {
            if (D3dCompiler.createBlob(_resource.hlsl.vertex.length, vertexBytecode) != 0)
            {
                throw new Dx11ResourceCreationException('ID3DBlob');
            }
            if (D3dCompiler.createBlob(_resource.hlsl.fragment.length, pixelBytecode) != 0)
            {
                throw new Dx11ResourceCreationException('ID3DBlob');
            }

            memcpy(vertexBytecode.getBufferPointer(), _resource.hlsl.vertex.getData().address(0), _resource.hlsl.vertex.length);
            memcpy(pixelBytecode.getBufferPointer(), _resource.hlsl.fragment.getData().address(0), _resource.hlsl.fragment.length);
        }
        else
        {
            var vertexErrors = new D3dBlob();
            if (D3dCompiler.compile(_resource.hlsl.vertex.getData(), null, null, null, 'VShader', 'vs_5_0', 0, 0, vertexBytecode, vertexErrors) != 0)
            {
                throw new DX11VertexCompilationError(_resource.id, '');
            }

            var pixelErrors = new D3dBlob();
            if (D3dCompiler.compile(_resource.hlsl.fragment.getData(), null, null, null, 'PShader', 'ps_5_0', 0, 0, pixelBytecode, pixelErrors) != 0)
            {
                throw new DX11FragmentCompilationError(_resource.id, '');
            }
        }

        // Create the vertex shader
        var vertexShader = new D3d11VertexShader();
        if (device.createVertexShader(vertexBytecode, null, vertexShader) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11VertexShader');
        }

        // Create the fragment shader
        var pixelShader = new D3d11PixelShader();
        if (device.createPixelShader(pixelBytecode, null, pixelShader) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11PixelShader');
        }

        // Create the shader layout.
        var elementPos = new D3d11InputElementDescription();
        elementPos.semanticName         = "POSITION";
        elementPos.semanticIndex        = 0;
        elementPos.format               = R32G32B32Float;
        elementPos.inputSlot            = 0;
        elementPos.alignedByteOffset    = 0;
        elementPos.inputSlotClass       = PerVertexData;
        elementPos.instanceDataStepRate = 0;
        var elementCol = new D3d11InputElementDescription();
        elementCol.semanticName         = "COLOR";
        elementCol.semanticIndex        = 0;
        elementCol.format               = R32G32B32A32Float;
        elementCol.inputSlot            = 0;
        elementCol.alignedByteOffset    = 12;
        elementCol.inputSlotClass       = PerVertexData;
        elementCol.instanceDataStepRate = 0;
        var elementTex = new D3d11InputElementDescription();
        elementTex.semanticName         = "TEXCOORD";
        elementTex.semanticIndex        = 0;
        elementTex.format               = R32G32Float;
        elementTex.inputSlot            = 0;
        elementTex.alignedByteOffset    = 28;
        elementTex.inputSlotClass       = PerVertexData;
        elementTex.instanceDataStepRate = 0;

        var inputLayout = new D3d11InputLayout();
        if (device.createInputLayout([ elementPos, elementCol, elementTex ], vertexBytecode, inputLayout) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11InputLayout');
        }

        // Create our shader and a class to store its resources.
        var resource = new ShaderInformation(_resource.layout, vertexShader, pixelShader, inputLayout);

        for (i in 0..._resource.layout.blocks.length)
        {
            var blockBytes       = BytesPacker.allocateBytes(Dx11, _resource.layout.blocks[i].values);
            var constantBuffer   = new D3d11Buffer();
            var blockDescription = new D3d11BufferDescription();
            blockDescription.byteWidth      = blockBytes.length;
            blockDescription.usage          = Dynamic;
            blockDescription.bindFlags      = ConstantBuffer;
            blockDescription.cpuAccessFlags = Write;

            if (device.createBuffer(blockDescription, null, constantBuffer) != Ok)
            {
                throw new Dx11ResourceCreationException('ID3D11Buffer');
            }

            resource.constantBuffers.push(constantBuffer);
            resource.bytes.push(blockBytes);
        }

        shaderResources.set(_resource.id, resource);
    }

    /**
     * Remove the D3D11 resources used by a shader.
     * @param _name Name of the shader to remove.
     */
    function removeShader(_resource : ShaderResource)
    {
        shaderResources[_resource.id].destroy();
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
        var imgData = new D3d11SubResourceData();
        imgData.systemMemory           = _resource.pixels.getData();
        imgData.systemMemoryPitch      = 4 * _resource.width;
        imgData.systemMemorySlicePatch = 0;

        // Texture description struct. Describes how our raw image data is formated and usage of the texture.
        var imgDesc = new D3d11Texture2DDescription();
        imgDesc.width              = _resource.width;
        imgDesc.height             = _resource.height;
        imgDesc.mipLevels          = 1;
        imgDesc.arraySize          = 1;
        imgDesc.format             = B8G8R8A8UNorm;
        imgDesc.sampleDesc.count   = 1;
        imgDesc.sampleDesc.quality = 0;
        imgDesc.usage              = Default;
        imgDesc.bindFlags          = ShaderResource | RenderTarget;
        imgDesc.cpuAccessFlags     = 0;
        imgDesc.miscFlags          = 0;

        var texture = new D3d11Texture2D();
        var resView = new D3d11ShaderResourceView();
        var rtvView = new D3d11RenderTargetView();

        if (device.createTexture2D(imgDesc, imgData, texture) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Texture2D');
        }
        if (device.createShaderResourceView(texture, null, resView) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11ShaderResourceView');
        }
        if (device.createRenderTargetView(texture, null, rtvView) != Ok)
        {
            throw new Dx11ResourceCreationException('D3D11RenderTargetView');
        }

        textureResources.set(_resource.id, new TextureInformation(texture, resView, rtvView));
    }

    /**
     * Free the D3D11 resources used by a texture.
     * @param _name Name of the texture to remove.
     */
    function removeTexture(_resource : ImageResource)
    {
        textureResources[_resource.id].destroy();
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
        // Set the render target
        if (_command.target != target)
        {
            target = _command.target;

            context.omSetRenderTargets([
                target == null ? backbuffer.renderTargetView : textureResources[target.id].renderTargetView
            ], depthStencilView);

            rendererStats.targetSwaps++;
        }

        // Write shader cbuffers and set it
        if (shader != _command.shader)
        {
            shader = _command.shader;

            // Apply the actual shader and input layout.
            var shaderResource = shaderResources.get(_command.shader.id);

            context.iaSetInputLayout(shaderResource.inputLayout);
            context.vsSetShader(shaderResource.vertexShader, null);
            context.psSetShader(shaderResource.pixelShader, null);

            rendererStats.shaderSwaps++;
        }

        depthStencilDescription.depthEnable    = _command.depth.depthTesting;
        depthStencilDescription.depthWriteMask = _command.depth.depthMasking ? All : Zero;
        depthStencilDescription.depthFunction  = getComparisonFunction(_command.depth.depthFunction);

        depthStencilDescription.stencilEnable    = _command.stencil.stencilTesting;
        depthStencilDescription.stencilReadMask  = _command.stencil.stencilFrontMask;
        depthStencilDescription.stencilWriteMask = _command.stencil.stencilBackMask;

        depthStencilDescription.frontFace.stencilFailOp      = getStencilOp(_command.stencil.stencilFrontTestFail);
        depthStencilDescription.frontFace.stencilDepthFailOp = getStencilOp(_command.stencil.stencilFrontDepthTestFail);
        depthStencilDescription.frontFace.stencilPassOp      = getStencilOp(_command.stencil.stencilFrontDepthTestPass);
        depthStencilDescription.frontFace.stencilFunction    = getComparisonFunction(_command.stencil.stencilFrontFunction);

        depthStencilDescription.backFace.stencilFailOp      = getStencilOp(_command.stencil.stencilBackTestFail);
        depthStencilDescription.backFace.stencilDepthFailOp = getStencilOp(_command.stencil.stencilBackDepthTestFail);
        depthStencilDescription.backFace.stencilPassOp      = getStencilOp(_command.stencil.stencilBackDepthTestPass);
        depthStencilDescription.backFace.stencilFunction    = getComparisonFunction(_command.stencil.stencilBackFunction);

        if (device.createDepthStencilState(depthStencilDescription, depthStencilState) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11DepthStencilState');
        }

        context.omSetDepthStencilState(depthStencilState, 1);

        // Update viewport
        if (_command.camera.viewport == null)
        {
            if (target == null)
            {
                cmdViewport.set(0, 0, backbuffer.width, backbuffer.height);
            }
            else
            {
                cmdViewport.set(0, 0, target.width, target.height);
            }
        }
        else
        {
            cmdViewport.copyFrom(_command.camera.viewport);
        }

        if (!viewport.equals(cmdViewport))
        {
            viewport.copyFrom(cmdViewport);

            nativeView.topLeftX = viewport.x;
            nativeView.topLeftY = viewport.y;
            nativeView.width    = viewport.w;
            nativeView.height   = viewport.h;

            context.rsSetViewports([ nativeView ]);

            rendererStats.viewportSwaps++;
        }

        // Update scissor
        if (_command.clip == null)
        {
            if (target == null)
            {
                cmdClip.set(0, 0, backbuffer.width, backbuffer.height);
            }
            else
            {
                cmdClip.set(0, 0, target.width, target.height);
            }
        }
        else
        {
            cmdClip.copyFrom(_command.clip);
        }

        if (!scissor.equals(cmdClip))
        {
            scissor.copyFrom(cmdClip);

            nativeClip.left   = Std.int(cmdClip.x);
            nativeClip.top    = Std.int(cmdClip.y);
            nativeClip.right  = Std.int(cmdClip.x + cmdClip.w);
            nativeClip.bottom = Std.int(cmdClip.y + cmdClip.h);

            context.rsSetScissorRects([ nativeClip ]);

            rendererStats.scissorSwaps++;
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

        if (device.createBlendState(blendDescription, blendState) != 0)
        {
            throw new Dx11ResourceCreationException('ID3D11BlendState');
        }
        context.omSetBlendState(blendState, [ 1, 1, 1, 1 ], 0xffffffff);

        rendererStats.blendSwaps++;

        // Set primitive topology
        if (topology != _command.primitive)
        {
            topology = _command.primitive;
            context.iaSetPrimitiveTopology(getPrimitive(_command.primitive));
        }

        // Always update the cbuffers and textures for now
        setShaderValues(_command);
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
        if (shaderResource.layout.textures.length <= _command.textures.length)
        {
            shaderTextureResources.resize(_command.textures.length);
            shaderTextureSamplers.resize(_command.textures.length);
            
            for (i in 0..._command.textures.length)
            {
                var texture = textureResources.get(_command.textures[i].id);
                var sampler = defaultSampler;
                if (_command.samplers[i] != null)
                {
                    var samplerHash = _command.samplers[i].hash();
                    if (!texture.samplers.exists(samplerHash))
                    {
                        sampler = createSampler(_command.samplers[i]);
                        texture.samplers[samplerHash] = sampler;
                    }
                    else
                    {
                        sampler = texture.samplers[samplerHash];
                    }
                }

                shaderTextureResources[i] = texture.shaderResourceView;
                shaderTextureSamplers [i] = sampler;
            }

            context.psSetShaderResources(0, shaderTextureResources);
            context.psSetSamplers(0, shaderTextureSamplers);

            rendererStats.textureSwaps += _command.textures.length;
        }
        else
        {
            throw 'DirectX 11 Backend Exception : More textures required by the shader than are provided by the draw command';
        }

        // Update the user defined shader blocks.
        // Data is packed into haxe bytes then copied over.

        for (i in 0...shaderResource.layout.blocks.length)
        {
            if (context.map(shaderResource.constantBuffers[i], 0, WriteDiscard, 0, mappedUniformBuffer) != Ok)
            {
                throw new DX11MappingBufferException(shaderResource.layout.blocks[i].name);
            }

            var ptr : Pointer<UInt8> = mappedUniformBuffer.data.reinterpret();

            if (shaderResource.layout.blocks[i].name == 'defaultMatrices')
            {
                buildCameraMatrices(_command.camera);

                var model      = bufferModelMatrix.exists(_command.id) ? bufferModelMatrix.get(_command.id) : dummyModelMatrix;
                var view       = _command.camera.view;
                var projection = _command.camera.projection;

                memcpy(ptr          , (projection : FastFloat32Array).getData().address(0), 64);
                memcpy(ptr.incBy(64), (view       : FastFloat32Array).getData().address(0), 64);
                memcpy(ptr.incBy(64), (model      : FastFloat32Array).getData().address(0), 64);
            }
            else
            {
                // Otherwise upload all user specified uniform values.
                // TODO : We should have some sort of error checking if the expected uniforms are not found.
                for (val in shaderResource.layout.blocks[i].values)
                {
                    var pos = BytesPacker.getPosition(Dx11, shaderResource.layout.blocks[i].values, val.name);

                    switch val.type
                    {
                        case Matrix4:
                            var mat = preferedUniforms.matrix4.exists(val.name) ? preferedUniforms.matrix4.get(val.name) : _command.shader.uniforms.matrix4.get(val.name);
                            memcpy(ptr.incBy(pos), (mat : FastFloat32Array).getData().address(0), 64);
                        case Vector4:
                            var vec = preferedUniforms.vector4.exists(val.name) ? preferedUniforms.vector4.get(val.name) : _command.shader.uniforms.vector4.get(val.name);
                            memcpy(ptr.incBy(pos), (vec : FastFloat32Array).getData().address(0), 16);
                        case Int:
                            var dst : Pointer<Int32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), preferedUniforms.int.exists(val.name) ? preferedUniforms.int.get(val.name) : _command.shader.uniforms.int.get(val.name));
                        case Float:
                            var dst : Pointer<Float32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), preferedUniforms.float.exists(val.name) ? preferedUniforms.float.get(val.name) : _command.shader.uniforms.float.get(val.name));
                    }
                }
            }

            context.unmap(shaderResource.constantBuffers[i], 0);

            context.vsSetConstantBuffers(i, [ shaderResource.constantBuffers[i] ]);
            context.psSetConstantBuffers(i, [ shaderResource.constantBuffers[i] ]);
        }
    }

    function createSampler(_sampler : SamplerState) : D3d11SamplerState
    {
        var samplerDescription = new D3d11SamplerDescription();
        samplerDescription.filter         = getFilterType(_sampler.minification);
        samplerDescription.addressU       = getEdgeClamping(_sampler.uClamping);
        samplerDescription.addressV       = getEdgeClamping(_sampler.vClamping);
        samplerDescription.addressW       = Clamp;
        samplerDescription.mipLodBias     = 0;
        samplerDescription.maxAnisotropy  = 1;
        samplerDescription.comparisonFunc = Never;
        samplerDescription.borderColor[0] = 1;
        samplerDescription.borderColor[1] = 1;
        samplerDescription.borderColor[2] = 1;
        samplerDescription.borderColor[3] = 1;
        samplerDescription.minLod         = -1;
        samplerDescription.minLod         = 1;

        var sampler = new D3d11SamplerState();
        if (device.createSamplerState(samplerDescription, sampler) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11SamplerState');
        }

        return sampler;
    }

    function buildCameraMatrices(_camera : Camera)
    {
        switch _camera.type
        {
            case Orthographic:
                var orth = (cast _camera : Camera2D);
                if (orth.dirty)
                {
                    orth.projection.makeHeterogeneousOrthographic(0, orth.viewport.w, 0, orth.viewport.h, -100, 100);
                    orth.view.copy(orth.transformation.world.matrix).invert();
                    orth.dirty = false;
                }
            case Projection:
                var proj = (cast _camera : Camera3D);
                if (proj.dirty)
                {
                    proj.projection.makeHeterogeneousPerspective(proj.fov, proj.aspect, proj.near, proj.far);
                    proj.view.copy(proj.transformation.world.matrix).invert();
                    proj.dirty = false;
                }
            case Custom:
                // Do nothing, user is responsible for building their custom camera matrices.
        }
    }

    inline function getBlend(_blend : BlendMode) : D3d11Blend
    {
        return switch _blend {
            case Zero             : Zero;
            case One              : One;
            case SrcAlphaSaturate : SourceAlphaSat;
            case SrcColor         : SourceColor;
            case OneMinusSrcColor : InverseSourceColor;
            case SrcAlpha         : SourceAlpha;
            case OneMinusSrcAlpha : InverseSourceAlpha;
            case DstAlpha         : DestinationAlpha;
            case OneMinusDstAlpha : InverseDestinationAlpha;
            case DstColor         : DestinationColor;
            case OneMinusDstColor : InverseDestinationColour;
        }
    }

    inline function getPrimitive(_primitive : PrimitiveType) : D3d11PrimitiveTopology
    {
        return switch _primitive
        {
            case Points        : PointList;
            case Lines         : LineList;
            case LineStrip     : LineStrip;
            case Triangles     : TriangleList;
            case TriangleStrip : TriangleStrip;
        }
    }

    inline function getComparisonFunction(_function : ComparisonFunction) : D3d11ComparisonFunction
    {
        return switch _function
        {
            case Always             : Always;
            case Never              : Never;
            case Equal              : Equal;
            case LessThan           : Less;
            case LessThanOrEqual    : LessEqual;
            case GreaterThan        : Greater;
            case GreaterThanOrEqual : GreaterEqual;
            case NotEqual           : NotEqual;
        }
    }

    inline function getStencilOp(_stencil : StencilFunction) : D3d11StencilOp
    {
        return switch _stencil
        {
            case Keep          : Keep;
            case Zero          : Zero;
            case Replace       : Replace;
            case Invert        : Invert;
            case Increment     : IncrSat;
            case IncrementWrap : Incr;
            case Decrement     : DecrSat;
            case DecrementWrap : Decr;
        }
    }

    inline function getFilterType(_filter : Filtering) : D3d11Filter
    {
        return switch _filter
        {
            case Nearest : MinMagMipPoint;
            case Linear  : MinMagMipLinear;
        }
    }

    inline function getEdgeClamping(_clamp : EdgeClamping) : D3d11TextureAddressMode
    {
        return switch _clamp
        {
            case Wrap   : Wrap;
            case Mirror : Mirror;
            case Clamp  : Clamp;
            case Border : Border;
        }
    }

    function onSizeChanged(_data : DisplayEventData)
    {
        resize(_data.width, _data.height);
    }

    function onSizeChangeRequest(_data : DisplayEventChangeRequest)
    {
        SDL.setWindowFullscreen(window, _data.fullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP : NONE);

        resize(_data.width, _data.height);
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
    public var renderTargetView : D3d11RenderTargetView;

    public function new(_width : Int, _height : Int, _viewportScale : Float)
    {
        width            = _width;
        height           = _height;
        viewportScale    = _viewportScale;
        renderTargetView = new D3d11RenderTargetView();
    }
}

/**
 * Holds the DirectX resources required for drawing a texture.
 */
private class TextureInformation
{
    /**
     * D3D11 Texture2D pointer.
     */
    public var texture : D3d11Texture2D;

    /**
     * D3D11 Shader Resource View to view the texture.
     */
    public var shaderResourceView : D3d11ShaderResourceView;

    /**
     * D3D11 Render Target View to draw to the texture.
     */
    public var renderTargetView : D3d11RenderTargetView;

    /**
     * D3D11 Sampler State to sample the textures data.
     */
    public var samplers : Map<Int, D3d11SamplerState>;

    public function new(_texture : D3d11Texture2D, _resView : D3d11ShaderResourceView, _rtvView : D3d11RenderTargetView)
    {
        texture            = _texture;
        shaderResourceView = _resView;
        renderTargetView   = _rtvView;
        samplers           = [];
    }

    public function destroy()
    {
        texture.release();
        shaderResourceView.release();
        renderTargetView.release();

        for (sampler in samplers)
        {
            sampler.release();
        }
    }
}

/**
 * Holds the DirectX resources required for setting and uploading data to a shader.
 */
private class ShaderInformation
{
    /**
     * JSON structure describing the textures and blocks in the shader.
     */
    public final layout : ShaderLayout;

    /**
     * D3D11 vertex shader pointer.
     */
    public final vertexShader : D3d11VertexShader;

    /**
     * D3D11 pixel shader pointer.
     */
    public final pixelShader : D3d11PixelShader;

    /**
     * D3D11 Vertex input description of this shader.
     */
    public final inputLayout : D3d11InputLayout;

    /**
     * Map to all D3D11 cbuffers used in this shader.
     * Array cannot be used since hxcpp doesn't like array of pointers.
     */
    public final constantBuffers : Array<D3d11Buffer>;

    /**
     * Array of all bytes for user the corresponding buffer.
     */
    public final bytes : Array<Bytes>;

    public function new(_layout : ShaderLayout, _vertex : D3d11VertexShader, _pixel : D3d11PixelShader, _input : D3d11InputLayout)
    {
        layout          = _layout;
        vertexShader    = _vertex;
        pixelShader     = _pixel;
        inputLayout     = _input;
        constantBuffers = [];
        bytes           = [];
    }

    public function destroy()
    {
        vertexShader.release();
        pixelShader.release();
        inputLayout.release();

        for (cbuffer in constantBuffers)
        {
            cbuffer.release();
        }
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

private class Dx11ResourceCreationException extends Exception
{
    public function new(_resource : String)
    {
        super('Failed to create resource $_resource');
    }
}

private class DX11NoShaderSourceException extends Exception
{
    public function new(_id : String)
    {
        super('$_id does not contain source code for a HLSL shader');
    }
}

private class DX11VertexCompilationError extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to compile the vertex shader for $_id : $_error');
    }
}

private class DX11FragmentCompilationError extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to compile the fragment shader for $_id : $_error');
    }
}

private class DX11MappingBufferException extends Exception
{
    public function new(_id : String)
    {
        super('Failed to map the buffer $_id');
    }
}

private class DX11FetchBackbufferException extends Exception
{
    public function new()
    {
        super('Failed to get the ID3DTexture2D for the backbuffer');
    }
}

private class DX11ResizeBackbufferException extends Exception
{
    public function new()
    {
        super('Failed to resize the backbuffer');
    }
}
