package uk.aidanlee.flurry.api.gpu.backend;

import haxe.ds.Vector;
import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader.D3d11Shader;
import d3d11.structures.D3d11Box;
import haxe.io.BytesData;
import haxe.Exception;
import haxe.ds.ReadOnlyArray;
import cpp.UInt8;
import cpp.Pointer;
import cpp.Stdlib.memcpy;
import sdl.Window;
import sdl.SDL;
import hxrx.ISubscription;
import hxrx.observer.Observer;
import dxgi.Dxgi;
import dxgi.structures.DxgiPresentParameters;
import dxgi.structures.DxgiSwapChainDescription;
import dxgi.interfaces.DxgiOutput;
import dxgi.interfaces.DxgiAdapter;
import dxgi.interfaces.DxgiFactory;
import dxgi.interfaces.DxgiSwapChain;
import dxgi.enumerations.DxgiFormat;
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
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererDx11Config;
import uk.aidanlee.flurry.api.gpu.StencilFunction;
import uk.aidanlee.flurry.api.gpu.ComparisonFunction;
import uk.aidanlee.flurry.api.gpu.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.BlendMode;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.EdgeClamping;
import uk.aidanlee.flurry.api.gpu.textures.Filtering;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.buffers.BufferData;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;

using cpp.NativeArray;

@:headerCode('#include <D3Dcompiler.h>
#include <d3d11_1.h>
#include "SDL_syswm.h"')
@:buildXml('<target id = "haxe">
    <lib name = "dxgi.lib"        if = "windows" unless = "static_link" />
    <lib name = "d3d11.lib"       if = "windows" unless = "static_link" />
    <lib name = "d3dcompiler.lib" if = "windows" unless = "static_link" />
</target>')
@:nullSafety(Off) class DX11Backend implements IRendererBackend
{
    /**
     * The number of floats in each vertex.
     */
    static final VERTEX_BYTE_SIZE = 36;

    /**
     * Signals for when shaders and images are created and removed.
     */
    final resourceEvents : ResourceEvents;

    /**
     * Signals for when a window change has been requested and dispatching back the result.
     */
    final displayEvents : DisplayEvents;

    /**
     * Parameters to define the area of the window to update when presenting.
     */
    final presentParameters : DxgiPresentParameters;

    /**
     * D3D11 device for this window.
     */
    final device : D3d11Device1;

    /**
     * Main D3D11 context for this windows device.
     */
    final context : D3d11DeviceContext1;

    /**
     * DXGI swapchain for presenting the backbuffer to the window.
     */
    final swapchain : DxgiSwapChain1;

    /**
     * Single main vertex buffer.
     */
    final vertexBuffer : D3d11Buffer;

    /**
     * Single main index buffer.
     */
    final indexBuffer : D3d11Buffer;

    /**
     * Buffer which will store all model, view, projection matrix collections.
     */
    final matrixBuffer : D3d11Buffer;

    /**
     * Buffer which will stor all uniform data.
     */
    final uniformBuffer : D3d11Buffer;

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
     * D3D11 resource used for mapping the matrix buffer.
     */
    final mappedMatrixBuffer : D3d11MappedSubResource;

    /**
     * D3D11 resource used for mapping the uniform buffer.
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
    final shaderResources : Map<ResourceID, ShaderInformation>;

    /**
     * Map of texture name to the D3D11 resources required to use the texture.
     */
    final textureResources : Map<ResourceID, TextureInformation>;

    /**
     * Sampler to use when none is provided.
     */
    final defaultSampler : D3d11SamplerState;

    /**
     * Rectangle used to hold the clip coordinates of the command currently being processed.
     */
    final cmdClip : Rectangle;

    /**
     * Rectangle used to hold the viewport coordinates of the command currently being processed.
     */
    final cmdViewport : Rectangle;

    /**
     * All the commands queued for uploading and drawing.
     */
    final commandQueue : Array<DrawCommand>;

    final resourceCreatedSubscription : ISubscription;

    final resourceRemovedSubscription : ISubscription;

    final displaySizeChangedSubscription : ISubscription;

    final displayChangeRequestSubscription : ISubscription;

    // State trackers

    var depth    : DepthState;
    var stencil  : StencilState;
    var blend    : BlendState;
    var topology : PrimitiveType;
    var shader   : ResourceID;
    var texture  : ResourceID;
    var target   : TargetState;

    // SDL Window

    var window : Window;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererDx11Config)
    {
        resourceEvents = _resourceEvents;
        displayEvents  = _displayEvents;

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
            throw new Exception('Unable to get DXGI information for the main SDL window : ${ SDL.getError() }');
        }

        shaderResources  = [];
        textureResources = [];
        shaderTextureResources = [ for (_ in 0...16) null ];
        shaderTextureSamplers  = [ for (_ in 0...16) null ];

        // Persistent D3D11 objects and descriptions
        swapchain               = new DxgiSwapChain1();
        swapchainTexture        = new D3d11Texture2D();
        device                  = new D3d11Device1();
        context                 = new D3d11DeviceContext1();
        depthStencilView        = new D3d11DepthStencilView();
        depthStencilState       = new D3d11DepthStencilState();
        depthStencilTexture     = new D3d11Texture2D();
        blendState              = new D3d11BlendState();
        rasterState             = new D3d11RasterizerState();
        mappedVertexBuffer      = new D3d11MappedSubResource();
        mappedIndexBuffer       = new D3d11MappedSubResource();
        mappedMatrixBuffer      = new D3d11MappedSubResource();
        mappedUniformBuffer     = new D3d11MappedSubResource();
        vertexBuffer            = new D3d11Buffer();
        indexBuffer             = new D3d11Buffer();
        matrixBuffer            = new D3d11Buffer();
        uniformBuffer           = new D3d11Buffer();
        depthStencilDescription = new D3d11DepthStencilDescription();

        // Setup the DXGI factory and get this windows adapter and output.
        final factory = new DxgiFactory2();
        final adapter = new DxgiAdapter();
        final output  = new DxgiOutput();

        if (Dxgi.createFactory2(0, factory) != Ok)
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
        final description = new DxgiSwapChainDescription1();
        description.sampleDesc.count   = 1;
        description.sampleDesc.quality = 0;
        description.width       = 0;
        description.height      = 0;
        description.format      = R8G8B8A8UNorm;
        description.stereo      = false;
        description.bufferCount = 2;
        description.bufferUsage = RenderTargetOutput;
        description.scaling     = Stretch;
        description.swapEffect  = FlipDiscard;
        description.alphaMode   = Unspecified;

        final deviceCreationFlags = if (_rendererConfig.debugDevice)
            D3d11CreateDeviceFlags.Debug | D3d11CreateDeviceFlags.Debuggable | D3d11CreateDeviceFlags.SingleThreaded
        else
            D3d11CreateDeviceFlags.None | D3d11CreateDeviceFlags.SingleThreaded;

        // Create our actual device and swapchain
        if (D3d11.createDevice(adapter, Unknown, null, deviceCreationFlags, [ Level11_1 ], D3d11.SdkVersion, device, null, context) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Device');
        }

        if (device.queryInterface(D3d11Device1.uuid, device) != 0)
        {
            throw new Exception('failed to cast ID3D11Device to an ID3D11Device1');
        }
        if (context.queryInterface(D3d11DeviceContext1.uuid, context) != 0)
        {
            throw new Exception('failed to cast ID3D11DeviceContext to an ID3D11DeviceContext1');
        }

        if (factory.createSwapChainForHwnd(device, hwnd, description, null, null, swapchain) != Ok)
        {
            throw new Dx11ResourceCreationException('IDXGISwapChain');
        }

        backbuffer        = new BackBuffer(_windowConfig.width, _windowConfig.height, 1);
        presentParameters = new DxgiPresentParameters();
        presentParameters.dirtyRectsCount = 0;

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
        final rasterDescription = new D3d11RasterizerDescription();
        rasterDescription.fillMode              = Solid;
        rasterDescription.cullMode              = None;
        rasterDescription.frontCounterClockwise = false;
        rasterDescription.depthBias             = 0;
        rasterDescription.slopeScaledDepthBias  = 0;
        rasterDescription.depthBiasClamp        = 0;
        rasterDescription.scissorEnable         = true;
        rasterDescription.depthClipEnable       = false;
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

        // Create the vertex buffer.
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.vertexBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = VertexBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, vertexBuffer) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Buffer');
        }

        // Create the index buffer
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.indexBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = IndexBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, indexBuffer) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Buffer');
        }

        // Create the matrix buffer
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.matrixBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = ConstantBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, matrixBuffer) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Buffer');
        }

        // Create the uniform buffer
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.uniformBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = ConstantBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, uniformBuffer) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11Buffer');
        }

        final depthTextureDesc = new D3d11Texture2DDescription();
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

        final depthStencilViewDescription = new D3d11DepthStencilViewDescription();
        depthStencilViewDescription.format             = D32FloatS8X24UInt;
        depthStencilViewDescription.viewDimension      = Texture2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        if (device.createDepthStencilView(depthStencilTexture, depthStencilViewDescription, depthStencilView) != 0)
        {
            throw new Dx11ResourceCreationException('ID3D11DepthStencilView');
        }

        // Create the default texture sampler
        final samplerDescription = new D3d11SamplerDescription();
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

        // Create the default depth and stencil testing
        depthStencilDescription.depthEnable    = false;
        depthStencilDescription.depthWriteMask = Zero;
        depthStencilDescription.depthFunction  = Always;

        depthStencilDescription.stencilEnable    = false;
        depthStencilDescription.stencilReadMask  = 0xff;
        depthStencilDescription.stencilWriteMask = 0xff;

        depthStencilDescription.frontFace.stencilFailOp      = Keep;
        depthStencilDescription.frontFace.stencilDepthFailOp = Keep;
        depthStencilDescription.frontFace.stencilPassOp      = Keep;
        depthStencilDescription.frontFace.stencilFunction    = Always;

        depthStencilDescription.backFace.stencilFailOp      = Keep;
        depthStencilDescription.backFace.stencilDepthFailOp = Keep;
        depthStencilDescription.backFace.stencilPassOp      = Keep;
        depthStencilDescription.backFace.stencilFunction    = Always;

        if (device.createDepthStencilState(depthStencilDescription, depthStencilState) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11DepthStencilState');
        }

        // Set the initial context state.
        final stride = (9 * 4);
        final offset = 0;
        context.iaSetIndexBuffer(indexBuffer, R16UInt, offset);
        context.iaSetVertexBuffer(0, vertexBuffer, stride, offset);
        context.iaSetPrimitiveTopology(TriangleList);
        context.rsSetViewport(nativeView);
        context.rsSetScissorRect(nativeClip);
        context.rsSetState(rasterState);
        context.omSetRenderTarget(backbuffer.renderTargetView, depthStencilView);
        context.omSetBlendState(blendState, [ 1, 1, 1, 1 ], 0xffffffff);
        context.omSetDepthStencilState(depthStencilState, 1);

        commandQueue = [];
        clearColour  = [
            _rendererConfig.clearColour.x,
            _rendererConfig.clearColour.y,
            _rendererConfig.clearColour.z,
            _rendererConfig.clearColour.w ];
        cmdClip     = new Rectangle();
        cmdViewport = new Rectangle();
        blend       = BlendState.none;
        depth       = DepthState.none;
        stencil     = StencilState.none;

        // Setup initial state tracker
        topology = Triangles;
        target   = Backbuffer;
        shader   = 0;
        texture  = 0;

        resourceCreatedSubscription = resourceEvents.created.subscribe(new Observer(onResourceCreated, null, null));
        resourceRemovedSubscription = resourceEvents.removed.subscribe(new Observer(onResourceRemoved, null, null));
        
        displaySizeChangedSubscription   = displayEvents.sizeChanged.subscribe(new Observer(onSizeChanged, null, null));
        displayChangeRequestSubscription = displayEvents.changeRequested.subscribe(new Observer(onSizeChangeRequest, null, null));
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function queue(_command : DrawCommand)
    {
        commandQueue.push(_command);
    }

    /**
     * Draw an array of commands. Command data must be uploaded to the GPU before being used.
     * @param _commands    Commands to draw.
     * @param _recordStats Record stats for this submit.
     */
    public function submit()
    {
        // Clear the backbuffer before drawing.
        context.clearRenderTargetView(backbuffer.renderTargetView, clearColour);
        context.clearDepthStencilView(depthStencilView, D3d11ClearFlag.Depth | D3d11ClearFlag.Stencil, 1, 0);

        // Upload and draw all commands
        uploadCommands();
        drawCommands();

        // Once we've submitted our draws present the backbuffer and clear the queue.
        swapchain.present1(0, 0, presentParameters);

        commandQueue.resize(0);

        // Set the backbuffer to the the target, this is required to get the next buffer in the flip present mode.
        context.omSetRenderTarget(backbuffer.renderTargetView, depthStencilView);
        target = Backbuffer;
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

        // Resise the swapchain texture
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

        // Rebuild the depth and stencil buffer
        depthStencilView.release();

        final depthTextureDesc = new D3d11Texture2DDescription();
        depthTextureDesc.width              = _width;
        depthTextureDesc.height             = _height;
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

        final depthStencilViewDescription = new D3d11DepthStencilViewDescription();
        depthStencilViewDescription.format             = D32FloatS8X24UInt;
        depthStencilViewDescription.viewDimension      = Texture2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        if (device.createDepthStencilView(depthStencilTexture, depthStencilViewDescription, depthStencilView) != 0)
        {
            throw new Dx11ResourceCreationException('ID3D11DepthStencilView');
        }

        // If we don't force a render target change here then the previous backbuffer pointer might still be bound and used.
        // This would cause nothing to render since that old backbuffer has now been released.
        context.omSetRenderTarget(backbuffer.renderTargetView, depthStencilView);
        target = Backbuffer;

        // Set the scissor to the new width and height.
        // This is needed to force a clip change so it doesn't stay with the old backbuffer size.
        nativeClip.left   = 0;
        nativeClip.top    = 0;
        nativeClip.right  = _width;
        nativeClip.bottom = _height;
        context.rsSetScissorRect(nativeClip);

        nativeView.topLeftX = 0;
        nativeView.topLeftY = 0;
        nativeView.width    = _width;
        nativeView.height   = _height;
        context.rsSetViewport(nativeView);
    }

    /**
     * Release all DX11 interface pointers.
     */
    public function cleanup()
    {
        resourceCreatedSubscription.unsubscribe();
        resourceRemovedSubscription.unsubscribe();

        displaySizeChangedSubscription.unsubscribe();
        displayChangeRequestSubscription.unsubscribe();

        SDL.destroyWindow(window);
    }

    public function uploadTexture(_frame : PageFrameResource, _data : BytesData)
    {
        final id          = _frame.page;
        final textureInfo = textureResources.get(id);

        final box = new D3d11Box();
        box.left   = _frame.x;
        box.top    = _frame.y;
        box.front  = 0;
        box.right  = _frame.x + _frame.width;
        box.bottom = _frame.y + _frame.height;
        box.back   = 1;

        context.updateSubresource(textureInfo.texture, 0, box, _data, _frame.width * 4, 0);
    }

    // #region SDL Window Management

    function createWindow(_options : FlurryWindowConfig)
    {        
        window = SDL.createWindow(_options.title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
    }

    // #endregion

    // #region resource handling

    function onResourceCreated(_resource : Resource)
    {
        if (_resource is PageResource)
        {
            createTexture(cast _resource);
        }
        else if (_resource is D3d11Shader)
        {
            createShader(cast _resource);
        }
    }

    function onResourceRemoved(_resource : Resource)
    {
        if (_resource is PageResource)
        {
            removeTexture(cast _resource);
        }
        else if (_resource is D3d11Shader)
        {
            removeShader(cast _resource);
        }
    }

    /**
     * Create the D3D11 resources required for a shader.
     * @param _vert   Vertex source.
     * @param _frag   Pixel source.
     * @param _layout JSON shader layout description.
     * @return Shader
     */
    function createShader(_resource : D3d11Shader)
    {
        if (shaderResources.exists(_resource.id))
        {
            return;
        }

        final vertexBytecode = new D3dBlob();
        final pixelBytecode  = new D3dBlob();

        if (D3dCompiler.createBlob(_resource.vertCode.length, vertexBytecode) != 0)
        {
            throw new Dx11ResourceCreationException('ID3DBlob');
        }
        if (D3dCompiler.createBlob(_resource.fragCode.length, pixelBytecode) != 0)
        {
            throw new Dx11ResourceCreationException('ID3DBlob');
        }

        memcpy(vertexBytecode.getBufferPointer(), _resource.vertCode.getData().address(0), _resource.vertCode.length);
        memcpy(pixelBytecode.getBufferPointer(), _resource.fragCode.getData().address(0), _resource.fragCode.length);

        // Create the vertex shader
        final vertexShader = new D3d11VertexShader();
        if (device.createVertexShader(vertexBytecode, null, vertexShader) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11VertexShader');
        }

        // Create the fragment shader
        final pixelShader = new D3d11PixelShader();
        if (device.createPixelShader(pixelBytecode, null, pixelShader) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11PixelShader');
        }

        // Create the shader layout.
        final elementPos = new D3d11InputElementDescription();
        elementPos.semanticName         = "TEXCOORD";
        elementPos.semanticIndex        = 0;
        elementPos.format               = R32G32B32Float;
        elementPos.inputSlot            = 0;
        elementPos.alignedByteOffset    = 0;
        elementPos.inputSlotClass       = PerVertexData;
        elementPos.instanceDataStepRate = 0;
        final elementCol = new D3d11InputElementDescription();
        elementCol.semanticName         = "TEXCOORD";
        elementCol.semanticIndex        = 1;
        elementCol.format               = R32G32B32A32Float;
        elementCol.inputSlot            = 0;
        elementCol.alignedByteOffset    = 12;
        elementCol.inputSlotClass       = PerVertexData;
        elementCol.instanceDataStepRate = 0;
        final elementTex = new D3d11InputElementDescription();
        elementTex.semanticName         = "TEXCOORD";
        elementTex.semanticIndex        = 2;
        elementTex.format               = R32G32Float;
        elementTex.inputSlot            = 0;
        elementTex.alignedByteOffset    = 28;
        elementTex.inputSlotClass       = PerVertexData;
        elementTex.instanceDataStepRate = 0;

        final inputLayout = new D3d11InputLayout();
        if (device.createInputLayout([ elementPos, elementCol, elementTex ], vertexBytecode, inputLayout) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11InputLayout');
        }

        // Create our shader and a class to store its resources.
        shaderResources.set(_resource.id, new ShaderInformation(_resource.vertBlocks, _resource.fragBlocks, _resource.textureCount, vertexShader, pixelShader, inputLayout));
    }

    /**
     * Remove the D3D11 resources used by a shader.
     * @param _name Name of the shader to remove.
     */
    function removeShader(_resource : D3d11Shader)
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
    function createTexture(_resource : PageResource)
    {
        // Sub resource struct to hold the raw image bytes.
        final imgData = new D3d11SubResourceData();
        imgData.systemMemory           = _resource.pixels.getData();
        imgData.systemMemoryPitch      = 4 * _resource.width;
        imgData.systemMemorySlicePatch = 0;

        // Texture description struct. Describes how our raw image data is formated and usage of the texture.
        final imgDesc = new D3d11Texture2DDescription();
        imgDesc.width              = _resource.width;
        imgDesc.height             = _resource.height;
        imgDesc.mipLevels          = 1;
        imgDesc.arraySize          = 1;
        imgDesc.format             = R8G8B8A8UNorm;
        imgDesc.sampleDesc.count   = 1;
        imgDesc.sampleDesc.quality = 0;
        imgDesc.usage              = Default;
        imgDesc.bindFlags          = ShaderResource | RenderTarget;
        imgDesc.cpuAccessFlags     = 0;
        imgDesc.miscFlags          = 0;

        final texture = new D3d11Texture2D();
        final resView = new D3d11ShaderResourceView();
        final rtvView = new D3d11RenderTargetView();

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

        textureResources.set(_resource.id, new TextureInformation(texture, resView, rtvView, imgDesc));
    }

    /**
     * Free the D3D11 resources used by a texture.
     * @param _name Name of the texture to remove.
     */
    function removeTexture(_resource : PageResource)
    {
        textureResources[_resource.id].destroy();
        textureResources.remove(_resource.id);
    }

    // #endregion

    function uploadCommands()
    {
        if (context.map(vertexBuffer, 0, WriteDiscard, 0, mappedVertexBuffer) != Ok)
        {
            throw new DX11MappingBufferException('Vertex Buffer');
        }
        if (context.map(indexBuffer, 0, WriteDiscard, 0, mappedIndexBuffer) != Ok)
        {
            throw new DX11MappingBufferException('Index Buffer');
        }
        if (context.map(matrixBuffer, 0, WriteDiscard, 0, mappedMatrixBuffer) != Ok)
        {
            throw new DX11MappingBufferException('Matrix Buffer');
        }
        if (context.map(uniformBuffer, 0, WriteDiscard, 0, mappedUniformBuffer) != Ok)
        {
            throw new DX11MappingBufferException('Uniform Buffer');
        }

        final vtxDst : Pointer<UInt8> = mappedVertexBuffer.data.reinterpret();
        final idxDst : Pointer<UInt8> = mappedIndexBuffer.data.reinterpret();
        final matDst : Pointer<UInt8> = mappedMatrixBuffer.data.reinterpret();
        final unfDst : Pointer<UInt8> = mappedUniformBuffer.data.reinterpret();

        var vtxUploaded = 0;
        var idxUploaded = 0;
        var matUploaded = 0;
        var unfUploaded = 0;

        for (command in commandQueue)
        {
            for (geometry in command.geometry)
            {
                // Upload vertex data
                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        memcpy(
                            idxDst.add(idxUploaded),
                            _indices.buffer.bytes.getData().address(_indices.buffer.byteOffset),
                            _indices.buffer.byteLength);

                        memcpy(
                            vtxDst.add(vtxUploaded),
                            _vertices.buffer.bytes.getData().address(_vertices.buffer.byteOffset),
                            _vertices.buffer.byteLength);

                        vtxUploaded += _vertices.buffer.byteLength;
                        idxUploaded += _indices.buffer.byteLength;
                    case UnIndexed(_vertices):
                        memcpy(
                            vtxDst.add(vtxUploaded),
                            _vertices.buffer.bytes.getData().address(_vertices.buffer.byteOffset),
                            _vertices.buffer.byteLength);

                        vtxUploaded += _vertices.buffer.byteLength;
                }

                final view       = command.camera.view;
                final projection = command.camera.projection;
                final model      = geometry.transformation.world.matrix;

                memcpy(matDst.add(matUploaded)      , (projection : Float32BufferData).bytes.getData().address((projection : Float32BufferData).byteOffset), 64);
                memcpy(matDst.add(matUploaded +  64), (view       : Float32BufferData).bytes.getData().address((view       : Float32BufferData).byteOffset), 64);
                memcpy(matDst.add(matUploaded + 128), (model      : Float32BufferData).bytes.getData().address((model      : Float32BufferData).byteOffset), 64);

                matUploaded = Maths.nextMultipleOff(matUploaded + 192, 256);

                // Upload uniform data
                for (block in command.uniforms)
                {
                    memcpy(
                        unfDst.add(unfUploaded),
                        block.buffer.bytes.getData().address(block.buffer.byteOffset),
                        block.buffer.byteLength);
    
                    unfUploaded = Maths.nextMultipleOff(unfUploaded + block.buffer.byteLength, 256);
                }
            }
        }

        context.unmap(vertexBuffer, 0);
        context.unmap(indexBuffer, 0);
        context.unmap(matrixBuffer, 0);
        context.unmap(uniformBuffer, 0);
    }

    function drawCommands()
    {
        var matOffset = 0;
        var idxOffset = 0;
        var vtxOffset = 0;
        var unfOffset = 0;

        for (command in commandQueue)
        {
            updateState(command);
            
            for (block in command.uniforms)
            {
                // Bind uniform buffers to both vertex and fragment stage
                // Might at some point be worth having the user specify which stages the blocks apply to.
                final buffer = uniformBuffer;
                final offset = cpp.NativeMath.idiv(unfOffset, 16);
                final length = Maths.nextMultipleOff(block.buffer.byteLength, 256);
                final info   = shaderResources[command.shader];

                final location = findBlockIndexByName(block.name, info.vertBlocks);
                if (location != -1)
                {
                    context.vsSetConstantBuffer1(location, buffer, offset, length);
                }

                final location = findBlockIndexByName(block.name, info.fragBlocks);
                if (location != -1)
                {
                    context.psSetConstantBuffer1(location, buffer, offset, length);
                }

                unfOffset = Maths.nextMultipleOff(unfOffset + block.buffer.byteLength, 256);
            }

            final shader   = shaderResources[command.shader];
            final location = findBlockIndexByName('flurry_matrices', shader.vertBlocks);

            for (geometry in command.geometry)
            {
                if (location != -1)
                {
                    // Bind Matrix CBuffer
                    final buffer = matrixBuffer;
                    final offset = cpp.NativeMath.idiv(matOffset, 16);
                    final length = 256;

                    context.vsSetConstantBuffer1(location, buffer, offset, length);
                }

                matOffset += 256;
                
                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        context.drawIndexed(_indices.shortAccess.length, idxOffset, vtxOffset);

                        idxOffset += _indices.shortAccess.length;
                        vtxOffset += Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);
                    case UnIndexed(_vertices):
                        final vertices = Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);

                        context.draw(vertices, vtxOffset);

                        vtxOffset += vertices;
                }
            }
        }
    }

    function findBlockIndexByName(_name : String, _blocks : Vector<String>)
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i] == _name)
            {
                return i;
            }
        }

        return -1;
    }

    /**
     * Sets the state of the D3D11 context to draw the provided command.
     * Will check against the current state to prevent unneeded state changes.
     * @param _command Command to get state info from.
     */
    function updateState(_command : DrawCommand)
    {
        updateFramebuffer(_command.target);
        updateShader(_command.shader);
        updateTextures(_command.shader, _command.textures, _command.samplers);
        updateBlend(_command.blending);
        updateTopology(_command.primitive);
        updateDepthStencil(_command.depth, _command.stencil);

        switch _command.camera.viewport
        {
            case None:
                switch target
                {
                    case Backbuffer:
                        updateViewport(0, 0, backbuffer.width, backbuffer.height);
                    case Texture(_id):
                        final info = textureResources[_id];
                        updateViewport(0, 0, info.description.width, info.description.height);
                }
            case Viewport(_x, _y, _width, _height):
                updateViewport(_x, _y, _width, _height);
        }

        switch _command.clip
        {
            case None:
                switch target
                {
                    case Backbuffer:
                        updateClip(0, 0, backbuffer.width, backbuffer.height);
                    case Texture(_id):
                        final info = textureResources[_id];
                        updateViewport(0, 0, info.description.width, info.description.height);
                }
            case Clip(_x, _y, _width, _height):
                updateClip(_x, _y, _width, _height);
        }
    }

    function updateFramebuffer(_newTarget : TargetState)
    {
        switch _newTarget
        {
            case Backbuffer:
                switch target
                {
                    case Backbuffer: // no op
                    case Texture(_):
                        context.omSetRenderTarget(backbuffer.renderTargetView, depthStencilView);
                }
            case Texture(_requested):
                switch target
                {
                    case Backbuffer:
                        context.omSetRenderTarget(textureResources[_requested].renderTargetView, null);
                    case Texture(_current):
                        if (_current != _requested)
                        {
                            context.omSetRenderTarget(textureResources[_requested].renderTargetView, null);
                        }
                }
        }

        target = _newTarget;
    }

    function updateShader(_newShader : ResourceID)
    {
        // Write shader cbuffers and set it
        if (shader != _newShader)
        {
            // Apply the actual shader and input layout.
            final shaderResource = shaderResources[_newShader];

            context.iaSetInputLayout(shaderResource.inputLayout);
            context.vsSetShader(shaderResource.vertexShader, null);
            context.psSetShader(shaderResource.pixelShader, null);
        }

        shader = _newShader;
    }

    function updateDepthStencil(_newDepth : DepthState, _newStencil : StencilState)
    {
        var update = false;
        
        if (depth != _newDepth)
        {
            depthStencilDescription.depthEnable    = _newDepth.enabled;
            depthStencilDescription.depthWriteMask = if (_newDepth.masking) All else Zero;
            depthStencilDescription.depthFunction  = getComparisonFunction(_newDepth.func);

            depth = _newDepth;

            update = true;
        }

        if (stencil != _newStencil)
        {
            depthStencilDescription.stencilEnable = _newStencil.enabled;

            depthStencilDescription.frontFace.stencilFailOp      = getStencilOp(_newStencil.frontTestFail);
            depthStencilDescription.frontFace.stencilDepthFailOp = getStencilOp(_newStencil.frontDepthTestFail);
            depthStencilDescription.frontFace.stencilPassOp      = getStencilOp(_newStencil.frontDepthTestPass);
            depthStencilDescription.frontFace.stencilFunction    = getComparisonFunction(_newStencil.frontFunc);

            depthStencilDescription.backFace.stencilFailOp      = getStencilOp(_newStencil.backTestFail);
            depthStencilDescription.backFace.stencilDepthFailOp = getStencilOp(_newStencil.backDepthTestFail);
            depthStencilDescription.backFace.stencilPassOp      = getStencilOp(_newStencil.backDepthTestPass);
            depthStencilDescription.backFace.stencilFunction    = getComparisonFunction(_newStencil.backFunc);

            stencil = _newStencil;

            update = true;
        }

        if (update)
        {
            if (device.createDepthStencilState(depthStencilDescription, depthStencilState) != Ok)
            {
                throw new Dx11ResourceCreationException('ID3D11DepthStencilState');
            }

            context.omSetDepthStencilState(depthStencilState, 1);
        }
    }

    function updateBlend(_newBlend : BlendState)
    {
        if (_newBlend != blend)
        {
            blendDescription.renderTarget[0].blendEnable    = _newBlend.enabled;
            blendDescription.renderTarget[0].srcBlend       = getBlend(_newBlend.srcRgb);
            blendDescription.renderTarget[0].srcBlendAlpha  = getBlend(_newBlend.srcAlpha);
            blendDescription.renderTarget[0].destBlend      = getBlend(_newBlend.dstRgb);
            blendDescription.renderTarget[0].destBlendAlpha = getBlend(_newBlend.dstAlpha);

            if (device.createBlendState(blendDescription, blendState) != 0)
            {
                throw new Dx11ResourceCreationException('ID3D11BlendState');
            }

            context.omSetBlendState(blendState, [ 1, 1, 1, 1 ], 0xffffffff);

            blend = _newBlend;
        }
    }

    function updateTopology(_newTopology : PrimitiveType)
    {
        if (topology != _newTopology)
        {
            context.iaSetPrimitiveTopology(getPrimitive(_newTopology));
            topology = _newTopology;
        }
    }

    function updateClip(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        if (nativeClip.left != _x || nativeClip.top != _y || nativeClip.right != (_x + _width) || nativeClip.bottom != (_y + _height))
        {
            nativeClip.left   = _x;
            nativeClip.top    = _y;
            nativeClip.right  = _x + _width;
            nativeClip.bottom = _y + _height;

            context.rsSetScissorRect(nativeClip);
        }
    }

    function updateViewport(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        if (nativeView.topLeftX != _x || nativeView.topLeftY != _y || nativeView.width != _width || nativeView.height != _height)
        {
            nativeView.topLeftX = _x;
            nativeView.topLeftY = _y;
            nativeView.width    = _width;
            nativeView.height   = _height;

            context.rsSetViewport(nativeView);
        }
    }

    function updateTextures(_shader : ResourceID, _textures : ReadOnlyArray<ResourceID>, _samplers : ReadOnlyArray<SamplerState>)
    {
        // If the shader description specifies more textures than the command provides throw an exception.
        // If less is specified than provided we just ignore the extra, maybe we should throw as well?
        final info  = shaderResources[_shader];
        final count = info.textures;

        if (_textures.length >= count)
        {
            shaderTextureResources.resize(count);
            shaderTextureSamplers.resize(count);

            // then go through each texture and bind it if it isn't already.
            for (i in 0...count)
            {
                var texture = textureResources[_textures[i]];
                var sampler = defaultSampler;
                if (i < _samplers.length)
                {
                    if (!texture.samplers.exists(_samplers[i]))
                    {
                        sampler = createSampler(_samplers[i]);
                        texture.samplers[_samplers[i]] = sampler;
                    }
                    else
                    {
                        sampler = texture.samplers[_samplers[i]];
                    }
                }

                shaderTextureResources[i] = texture.shaderResourceView;
                shaderTextureSamplers [i] = sampler;
            }

            context.psSetShaderResources(0, shaderTextureResources);
            context.psSetSamplers(0, shaderTextureSamplers);
        }
        else
        {
            throw new Exception('Not enough textures provided by the draw command. Expected $count but received ${_textures.length}');
        }
    }

    function createSampler(_sampler : SamplerState) : D3d11SamplerState
    {
        final samplerDescription = new D3d11SamplerDescription();
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

        final sampler = new D3d11SamplerState();
        if (device.createSamplerState(samplerDescription, sampler) != Ok)
        {
            throw new Dx11ResourceCreationException('ID3D11SamplerState');
        }

        return sampler;
    }

    function getBlend(_blend : BlendMode) : D3d11Blend
    {
        return switch _blend
        {
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

    function getPrimitive(_primitive : PrimitiveType) : D3d11PrimitiveTopology
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

    function getComparisonFunction(_function : ComparisonFunction) : D3d11ComparisonFunction
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

    function getStencilOp(_stencil : StencilFunction) : D3d11StencilOp
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

    function getFilterType(_filter : Filtering) : D3d11Filter
    {
        return switch _filter
        {
            case Nearest : MinMagMipPoint;
            case Linear  : MinMagMipLinear;
        }
    }

    function getEdgeClamping(_clamp : EdgeClamping) : D3d11TextureAddressMode
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
    public final viewportScale : Float;

    /**
     * Framebuffer object for the backbuffer.
     */
    public final renderTargetView : D3d11RenderTargetView;

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
    public final texture : D3d11Texture2D;

    /**
     * D3D11 Shader Resource View to view the texture.
     */
    public final shaderResourceView : D3d11ShaderResourceView;

    /**
     * D3D11 Render Target View to draw to the texture.
     */
    public final renderTargetView : D3d11RenderTargetView;

    /**
     * D3D11 Texture 2D description, contains info on the underlying texture data.
     */
    public final description : D3d11Texture2DDescription;

    /**
     * D3D11 Sampler State to sample the textures data.
     */
    public final samplers : Map<SamplerState, D3d11SamplerState>;

    public function new(_texture, _resView, _rtvView, _description)
    {
        texture            = _texture;
        shaderResourceView = _resView;
        renderTargetView   = _rtvView;
        description        = _description;
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
    public final vertBlocks : Vector<String>;

    public final fragBlocks : Vector<String>;

    public final textures : Int;

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

    public function new(_vertBlocks, _fragBlocks, _textures, _vertex, _pixel, _input)
    {
        vertBlocks   = _vertBlocks;
        fragBlocks   = _fragBlocks;
        textures     = _textures;
        vertexShader = _vertex;
        pixelShader  = _pixel;
        inputLayout  = _input;
    }

    public function destroy()
    {
        vertexShader.release();
        pixelShader.release();
        inputLayout.release();
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

    public function new(_vertices : Int, _vertexOffset : Int, _indices : Int, _indexOffset)
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
