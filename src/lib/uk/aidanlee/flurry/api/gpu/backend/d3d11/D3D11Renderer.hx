package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import VectorMath;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
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
import uk.aidanlee.flurry.api.gpu.backend.d3d11.D3D11Conversions;
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

using hxrx.observables.Observables;

using Safety;
using cpp.NativeArray;

@:headerCode('#include <D3Dcompiler.h>
#include <d3d11_1.h>
#include "SDL_syswm.h"')
@:buildXml('<target id = "haxe">
    <lib name = "dxgi.lib"        if = "windows" unless = "static_link" />
    <lib name = "d3d11.lib"       if = "windows" unless = "static_link" />
    <lib name = "d3dcompiler.lib" if = "windows" unless = "static_link" />
</target>')
@:nullSafety(Off) class D3D11Renderer extends Renderer
{
    final displayEvents : DisplayEvents;

    final windowConfig : FlurryWindowConfig;

    final rendererConfig : FlurryRendererDx11Config;

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
     * Buffer which will stor all uniform data.
     */
    final uniformBuffer : D3d11Buffer;

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
     * Render target view for drawing to the backbuffer.
     */
    final backbufferRenderTargetView : D3d11RenderTargetView;

    /**
     * The texture used for the depth and stencil view.
     */
    final depthStencilTexture : D3d11Texture2D;

    /**
     * Map of shader name to the D3D11 resources required to use the shader.
     */
    final shaderResources : Map<ResourceID, D3D11ShaderInformation>;

    /**
     * Map of texture name to the D3D11 resources required to use the texture.
     */
    final textureResources : Map<ResourceID, D3D11TextureInformation>;

    /**
     * Normalised RGBA colour to clear the backbuffer with each frame.
     */
    final clearColour : Array<Float>;

    /**
     * Storage for all pipeline objects.
     */
    final pipelines : Vector<Null<D3D11PipelineState>>;

    /**
     * Object which caches d3d11 sampler objects.
     */
    final samplers : D3D11SamplerCache;

    /**
     * SDL window handle.
     */
    final window : Window;

    public function new(_resourceEvents, _displayEvents, _windowConfig, _rendererConfig)
    {
        super(_resourceEvents);

        displayEvents  = _displayEvents;
        windowConfig   = _windowConfig;
        rendererConfig = _rendererConfig;
        window         = SDL.createWindow(
            _windowConfig.title,
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            _windowConfig.width,
            _windowConfig.height,
            SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);

        resourceEvents
            .created
            .filter(r -> r is D3d11Shader)
            .subscribeFunction(createShader);

        resourceEvents
            .removed
            .filter(r -> r is D3d11Shader)
            .subscribeFunction(deleteShader);

        displayEvents
            .changeRequested
            .subscribeFunction(onSizeChangeRequest);

        displayEvents
            .sizeChanged
            .subscribeFunction(onSizeChanged);

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

        // Persistent D3D11 objects and descriptions
        swapchain                  = new DxgiSwapChain1();
        swapchainTexture           = new D3d11Texture2D();
        device                     = new D3d11Device1();
        context                    = new D3d11DeviceContext1();
        depthStencilView           = new D3d11DepthStencilView();
        depthStencilState          = new D3d11DepthStencilState();
        depthStencilTexture        = new D3d11Texture2D();
        rasterState                = new D3d11RasterizerState();
        vertexBuffer               = new D3d11Buffer();
        indexBuffer                = new D3d11Buffer();
        uniformBuffer              = new D3d11Buffer();
        backbufferRenderTargetView = new D3d11RenderTargetView();
        depthStencilDescription    = new D3d11DepthStencilDescription();

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

        final deviceCreationFlags = D3d11CreateDeviceFlags.Debug | D3d11CreateDeviceFlags.SingleThreaded;

        // Create our actual device and swapchain
        if (D3d11.createDevice(adapter, Unknown, null, deviceCreationFlags, [ Level11_1 ], D3d11.SdkVersion, device, null, context) != Ok)
        {
            throw new Exception('ID3D11Device');
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
            throw new Exception('IDXGISwapChain');
        }

        presentParameters = new DxgiPresentParameters();
        presentParameters.dirtyRectsCount = 0;

        if (swapchain.getBuffer(0, NativeID3D11Texture2D.uuid(), swapchainTexture) != Ok)
        {
            throw new Exception('Failed to get swapchain buffer');
        }
        if (device.createRenderTargetView(swapchainTexture, null, backbufferRenderTargetView) != 0)
        {
            throw new Exception('ID3D11RenderTargetView');
        }

        // Setup the rasterizer state.
        final rasterDescription = new D3d11RasterizerDescription();
        rasterDescription.fillMode              = Solid;
        rasterDescription.cullMode              = None;
        rasterDescription.frontCounterClockwise = false;
        rasterDescription.depthBias             = 0;
        rasterDescription.slopeScaledDepthBias  = 0;
        rasterDescription.depthBiasClamp        = 0;
        rasterDescription.scissorEnable         = false;
        rasterDescription.depthClipEnable       = false;
        rasterDescription.multisampleEnable     = false;
        rasterDescription.antialiasedLineEnable = false;

        if (device.createRasterizerState(rasterDescription, rasterState) != Ok)
        {
            throw new Exception('ID3D11RasterizerState');
        }

        // Create the vertex buffer.
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.vertexBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = VertexBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, vertexBuffer) != Ok)
        {
            throw new Exception('ID3D11Buffer');
        }

        // Create the index buffer
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.indexBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = IndexBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, indexBuffer) != Ok)
        {
            throw new Exception('ID3D11Buffer');
        }

        // Create the uniform buffer
        final bufferDesc = new D3d11BufferDescription();
        bufferDesc.byteWidth      = _rendererConfig.uniformBufferSize;
        bufferDesc.usage          = Dynamic;
        bufferDesc.bindFlags      = ConstantBuffer;
        bufferDesc.cpuAccessFlags = Write;

        if (device.createBuffer(bufferDesc, null, uniformBuffer) != Ok)
        {
            throw new Exception('ID3D11Buffer');
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
            throw new Exception('ID3D11Texture2D');
        }

        final depthStencilViewDescription = new D3d11DepthStencilViewDescription();
        depthStencilViewDescription.format             = D32FloatS8X24UInt;
        depthStencilViewDescription.viewDimension      = Texture2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        if (device.createDepthStencilView(depthStencilTexture, depthStencilViewDescription, depthStencilView) != 0)
        {
            throw new Exception('ID3D11DepthStencilView');
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
            throw new Exception('ID3D11DepthStencilState');
        }

        // Set the initial context state.
        final stride = (9 * 4);
        final offset = 0;
        context.iaSetIndexBuffer(indexBuffer, R16UInt, offset);
        context.iaSetVertexBuffer(0, vertexBuffer, stride, offset);
        context.rsSetState(rasterState);
        context.omSetRenderTarget(backbufferRenderTargetView, depthStencilView);

        pipelines    = new Vector(1024);
        samplers     = new D3D11SamplerCache(device);
        clearColour  = [
            _rendererConfig.clearColour.x,
            _rendererConfig.clearColour.y,
            _rendererConfig.clearColour.z,
            _rendererConfig.clearColour.w
        ];
    }

    public function getGraphicsContext()
    {
        // Clear the backbuffer before drawing.
        context.clearRenderTargetView(backbufferRenderTargetView, clearColour);
        context.clearDepthStencilView(depthStencilView, D3d11ClearFlag.Depth | D3d11ClearFlag.Stencil, 1, 0);

        // Set the backbuffer as the target, this is required to get the next buffer in the flip present mode.
        context.omSetRenderTarget(backbufferRenderTargetView, depthStencilView);

        return new D3D11GraphicsContext(
            context,
            samplers,
            pipelines,
            shaderResources,
            textureResources,
            vertexBuffer,
            indexBuffer,
            uniformBuffer);
    }

    public function present()
    {
        if (swapchain.present1(0, 0, presentParameters) != Ok)
        {
            throw new Exception('Failed to present swapchain');
        }
    }

	public function createPipeline(_state : PipelineState)
    {
        final id         = new PipelineID(0);
        final dsState    = new D3d11DepthStencilState();
        final blendState = new D3d11BlendState();

        // Create the depth and stencil state.
        final dsDesc = new D3d11DepthStencilDescription();
        dsDesc.depthEnable    = _state.depth.enabled;
        dsDesc.depthWriteMask = if (_state.depth.masking) All else Zero;
        dsDesc.depthFunction  = getComparisonFunction(_state.depth.func);

        dsDesc.stencilEnable    = _state.stencil.enabled;
        dsDesc.stencilReadMask  = 0xff;
        dsDesc.stencilWriteMask = 0xff;

        dsDesc.frontFace.stencilFailOp      = getStencilOp(_state.stencil.frontTestFail);
        dsDesc.frontFace.stencilDepthFailOp = getStencilOp(_state.stencil.frontDepthTestFail);
        dsDesc.frontFace.stencilPassOp      = getStencilOp(_state.stencil.frontDepthTestPass);
        dsDesc.frontFace.stencilFunction    = getComparisonFunction(_state.stencil.frontFunc);

        dsDesc.backFace.stencilFailOp      = getStencilOp(_state.stencil.backTestFail);
        dsDesc.backFace.stencilDepthFailOp = getStencilOp(_state.stencil.backDepthTestFail);
        dsDesc.backFace.stencilPassOp      = getStencilOp(_state.stencil.backDepthTestPass);
        dsDesc.backFace.stencilFunction    = getComparisonFunction(_state.stencil.backFunc);

        if (device.createDepthStencilState(dsDesc, dsState) != Ok)
        {
            throw new Exception('ID3D11DepthStencilState');
        }

        // Create the blend state.
        final blendDesc = new D3d11BlendDescription();
        blendDesc.alphaToCoverageEnable          = false;
        blendDesc.independentBlendEnable         = false;
        blendDesc.renderTarget[0].blendEnable    = _state.blend.enabled;
        blendDesc.renderTarget[0].srcBlend       = getBlend(_state.blend.srcRgb);
        blendDesc.renderTarget[0].srcBlendAlpha  = getBlend(_state.blend.srcAlpha);
        blendDesc.renderTarget[0].destBlend      = getBlend(_state.blend.dstRgb);
        blendDesc.renderTarget[0].destBlendAlpha = getBlend(_state.blend.dstAlpha);
        blendDesc.renderTarget[0].blendOp        = Add;
        blendDesc.renderTarget[0].blendOpAlpha   = Add;
        blendDesc.renderTarget[0].renderTargetWriteMask = D3d11ColorWriteEnable.All;

        if (device.createBlendState(blendDesc, blendState) != Ok)
        {
            throw new Exception('ID3D11BlendState');
        }

        pipelines[id] = new D3D11PipelineState(
            _state.shader,
            dsState,
            blendState,
            getPrimitive(_state.primitive));

		return id;
	}

	public function deletePipeline(_id : PipelineID)
    {
        pipelines[_id] = null;
    }

	public function createShader(_resource : Resource)
    {
        if (shaderResources.exists(_resource.id))
        {
            return;
        }

        final shader         = Std.downcast(_resource, D3d11Shader);
        final vertexBytecode = new D3dBlob();
        final pixelBytecode  = new D3dBlob();

        if (D3dCompiler.createBlob(shader.vertCode.length, vertexBytecode) != 0)
        {
            throw new Exception('ID3DBlob');
        }
        if (D3dCompiler.createBlob(shader.fragCode.length, pixelBytecode) != 0)
        {
            throw new Exception('ID3DBlob');
        }

        memcpy(vertexBytecode.getBufferPointer(), shader.vertCode.getData().address(0), shader.vertCode.length);
        memcpy(pixelBytecode.getBufferPointer(), shader.fragCode.getData().address(0), shader.fragCode.length);

        // Create the vertex shader
        final vertexShader = new D3d11VertexShader();
        if (device.createVertexShader(vertexBytecode, null, vertexShader) != Ok)
        {
            throw new Exception('ID3D11VertexShader');
        }

        // Create the fragment shader
        final pixelShader = new D3d11PixelShader();
        if (device.createPixelShader(pixelBytecode, null, pixelShader) != Ok)
        {
            throw new Exception('ID3D11PixelShader');
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
            throw new Exception('ID3D11InputLayout');
        }

        // Create our shader and a class to store its resources.
        shaderResources.set(_resource.id, new D3D11ShaderInformation(shader.vertBlocks, shader.fragBlocks, shader.textureCount, vertexShader, pixelShader, inputLayout));
    }

	public function deleteShader(_resource : Resource)
    {
        shaderResources[_resource.id].destroy();
        shaderResources.remove(_resource.id);
    }

    public function createTexture(_resource : PageResource)
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
            throw new Exception('ID3D11Texture2D');
        }
        if (device.createShaderResourceView(texture, null, resView) != Ok)
        {
            throw new Exception('ID3D11ShaderResourceView');
        }
        if (device.createRenderTargetView(texture, null, rtvView) != Ok)
        {
            throw new Exception('D3D11RenderTargetView');
        }

        textureResources.set(_resource.id, new D3D11TextureInformation(texture, resView, rtvView, imgDesc));
    }

    public function deleteTexture(_resource : PageResource)
    {
        textureResources[_resource.id].destroy();
        textureResources.remove(_resource.id);
    }

    function onSizeChanged(_data : DisplayEventData)
    {
        resize(_data.width, _data.height);
    }

    function onSizeChangeRequest(_data : DisplayEventChangeRequest)
    {
        SDL.setWindowFullscreen(window, if (_data.fullscreen) SDL_WINDOW_FULLSCREEN_DESKTOP else NONE);

        resize(_data.width, _data.height);
    }

    /**
     * Resize the backbuffer and re-assign the backbuffer pointer.
     * @param _width  New width of the window.
     * @param _height New height of the window.
     */
    function resize(_width : Int, _height : Int)
    {
        context.omSetRenderTargets(null, null);

        backbufferRenderTargetView.release();
        swapchainTexture.release();

        // Resise the swapchain texture
        if (swapchain.resizeBuffers(0, _width, _height, Unknown, 0) != Ok)
        {
            throw new Exception('Failed to resize swapchain');
        }
        if (swapchain.getBuffer(0, NativeID3D11Texture2D.uuid(), swapchainTexture) != Ok)
        {
            throw new Exception('Failed to get swapchain buffer');
        }
        if (device.createRenderTargetView(swapchainTexture, null, backbufferRenderTargetView) != Ok)
        {
            throw new Exception('ID3D11RenderTargetView');
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

        if (device.createTexture2D(depthTextureDesc, null, depthStencilTexture) != Ok)
        {
            throw new Exception('ID3D11Texture2D');
        }

        final depthStencilViewDescription = new D3d11DepthStencilViewDescription();
        depthStencilViewDescription.format             = D32FloatS8X24UInt;
        depthStencilViewDescription.viewDimension      = Texture2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        if (device.createDepthStencilView(depthStencilTexture, depthStencilViewDescription, depthStencilView) != Ok)
        {
            throw new Exception('ID3D11DepthStencilView');
        }
    }
}