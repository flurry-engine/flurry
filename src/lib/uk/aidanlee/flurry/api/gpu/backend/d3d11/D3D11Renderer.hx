package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceState;
import d3d11.constants.D3d11Error;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.resources.builtin.ShaderResource;
import haxe.exceptions.NotImplementedException;
import uk.aidanlee.flurry.api.gpu.pipeline.VertexFormat;
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
import uk.aidanlee.flurry.api.gpu.backend.d3d11.D3D11Conversions;
import uk.aidanlee.flurry.api.gpu.pipeline.BlendMode;
import uk.aidanlee.flurry.api.gpu.pipeline.DepthState;
import uk.aidanlee.flurry.api.gpu.pipeline.BlendState;
import uk.aidanlee.flurry.api.gpu.pipeline.StencilState;
import uk.aidanlee.flurry.api.gpu.pipeline.PrimitiveType;
import uk.aidanlee.flurry.api.gpu.pipeline.StencilFunction;
import uk.aidanlee.flurry.api.gpu.pipeline.ComparisonFunction;
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
     * Normalised RGBA colour to clear all user surfaces with each frame.
     */
    final surfaceClearColour : Array<Float>;

    /**
     * Storage for all pipeline objects.
     */
    final pipelines : Vector<Null<D3D11PipelineState>>;

    /**
     * Storage for all surface objects.
     */
    final surfaces : Vector<Null<D3D11SurfaceInformation>>;

    /**
     * Object which caches d3d11 sampler objects.
     */
    final samplers : D3D11SamplerCache;

    /**
     * Re-usable graphics context.
     */
    final graphicsContext : D3D11GraphicsContext;

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
        device                     = new D3d11Device1();
        context                    = new D3d11DeviceContext1();
        rasterState                = new D3d11RasterizerState();
        vertexBuffer               = new D3d11Buffer();
        indexBuffer                = new D3d11Buffer();
        uniformBuffer              = new D3d11Buffer();

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

        final deviceCreationFlags =
            if (_rendererConfig.debugDevice)
                D3d11CreateDeviceFlags.Debug | D3d11CreateDeviceFlags.SingleThreaded
            else
                D3d11CreateDeviceFlags.SingleThreaded;

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

        // Default presentation params.
        presentParameters = new DxgiPresentParameters();
        presentParameters.dirtyRectsCount = 0;

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

        // Set the initial context state.
        context.rsSetState(rasterState);

        pipelines    = new Vector(1024);
        surfaces     = new Vector(1024);
        samplers     = new D3D11SamplerCache(device);
        clearColour  = [
            _rendererConfig.clearColour.x,
            _rendererConfig.clearColour.y,
            _rendererConfig.clearColour.z,
            _rendererConfig.clearColour.w
        ];
        surfaceClearColour = [ 1, 1, 1, 0 ];
        graphicsContext = new D3D11GraphicsContext(
            context,
            samplers,
            pipelines,
            surfaces,
            shaderResources,
            textureResources,
            vertexBuffer,
            indexBuffer,
            uniformBuffer);

        createBackbufferSurface(_windowConfig.width, _windowConfig.height);
    }

    /**
     * Returns the D3D11 renderer context which allows setting the state of the ID3D11DeviceContext and uploading vertex and index data.
     * Calling this function also clears all surfaces. The texture attachment gets set to white, the depth buffer gets 1 written,
     * and the stencil gets 0 written. The backbuffer texture attachment is set to the clear colour instead.
     */
    public function getGraphicsContext()
    {
        // Surface 0 is the backbuffer and should be cleared with a different colour.
        for (i in 0...surfaces.length)
        {
            switch surfaces[i]
            {
                case null:
                    //
                case surface if (i != SurfaceID.backbuffer && surface.state.volatile):
                    context.clearRenderTargetView(surface.surfaceRenderView, surfaceClearColour);
                    context.clearDepthStencilView(surface.depthStencilView, D3d11ClearFlag.Depth | D3d11ClearFlag.Stencil, 1, 0);
            }
        }

        // We need to set the backbuffer as the target in flip present mode to get the next backbuffer.
        switch surfaces[SurfaceID.backbuffer]
        {
            case null:
                throw new Exception('Backbuffer surface was null');
            case backbuffer:
                context.clearRenderTargetView(backbuffer.surfaceRenderView, clearColour);
                context.clearDepthStencilView(backbuffer.depthStencilView, D3d11ClearFlag.Depth | D3d11ClearFlag.Stencil, 1, 0);

                context.omSetRenderTarget(backbuffer.surfaceRenderView, backbuffer.depthStencilView);
        }

        return graphicsContext;
    }

    /**
     * Present the swapchains texture. Do not attempt to do any vsync.
     */
    public function present()
    {
        if (swapchain.present1(0, 0, presentParameters) != Ok)
        {
            throw new Exception('Failed to present swapchain');
        }
    }

    /**
	 * Given a pipeline state create ID3D11 objects which match the request.
     * An ID representing the created state object is returned.
     * 
     * TODO :
     * In the future a lot of the created ID3D11 objects should be cached and re-used between pipelines.
     * The majority of pipelines are probably going to use the same blend and depth / stencil settings,
     * we don't need to create new ID3D11 objects for all of them.
     * 
	 * @param _state Object holding the required state of the new pipeline.
	 */
	public function createPipeline(_state : PipelineState)
    {
        final id         = new PipelineID(getNextPipelineID());
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
        blendDesc.renderTarget[0].srcBlend       = getBlend(_state.blend.srcFactor);
        blendDesc.renderTarget[0].srcBlendAlpha  = getBlend(_state.blend.srcFactor);
        blendDesc.renderTarget[0].destBlend      = getBlend(_state.blend.dstFactor);
        blendDesc.renderTarget[0].destBlendAlpha = getBlend(_state.blend.dstFactor);
        blendDesc.renderTarget[0].blendOp        = getBlendOp(_state.blend.op);
        blendDesc.renderTarget[0].blendOpAlpha   = getBlendOp(_state.blend.op);
        blendDesc.renderTarget[0].renderTargetWriteMask = D3d11ColorWriteEnable.All;

        var result = D3d11Error.Ok;
        if (Ok != (result = device.createBlendState(blendDesc, blendState)))
        {
            throw new Exception('Error creating blend state, HRESULT : $result');
        }

        pipelines[id] = new D3D11PipelineState(
            _state.shader,
            _state.surface,
            dsState,
            blendState,
            getPrimitive(_state.primitive));

		return id;
	}

	/**
	 * Delete a pipeline by releasing all native ID3D11 objects.
	 * @param _id ID of the pipeline to delete.
	 */
	public function deletePipeline(_id : PipelineID)
    {
        switch pipelines[_id]
        {
            case null:
                // Pipeline does not exist, should we throw instead?
            case pipeline:
                pipeline.blendState.release();
                pipeline.depthStencilState.release();

                pipelines[_id] = null;
        }
    }

    /**
     * Create all the ID3D11 objects required for drawing to an off screen target.
     * Surfaces are currently always created with a depth and stencil buffer and the texture
     * is RGBA format.
     * @param _state 
     */
    public function createSurface(_state : SurfaceState)
    {
        final id = getNextSurfaceID();

        // Create an empty texture and the structures needed to render to it.
        final imgDesc = new D3d11Texture2DDescription();
        imgDesc.width              = _state.width;
        imgDesc.height             = _state.height;
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
        if (device.createTexture2D(imgDesc, null, texture) != Ok)
        {
            throw new Exception('ID3D11Texture2D');
        }

        final shaderView = new D3d11ShaderResourceView();
        if (device.createShaderResourceView(texture, null, shaderView) != Ok)
        {
            throw new Exception('ID3D11ShaderResourceView');
        }

        final targetView = new D3d11RenderTargetView();
        if (device.createRenderTargetView(texture, null, targetView) != Ok)
        {
            throw new Exception('ID3D11RenderTargetView');
        }

        final depthStencilTexture = new D3d11Texture2D();
        final depthStencilView    = new D3d11DepthStencilView();

        if (_state.depthStencilBuffer)
        {
            // Now create a depth texture for the target
            final depthTextureDesc = new D3d11Texture2DDescription();
            depthTextureDesc.width              = _state.width;
            depthTextureDesc.height             = _state.height;
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
        }

        surfaces[id] =
            new D3D11SurfaceInformation(
                _state,
                texture,
                shaderView,
                targetView,
                depthStencilTexture,
                depthStencilView);

        return new SurfaceID(id);
    }

    /**
     * Delete a surface by releasing all native ID3D11 objects.
     * @param _id ID of the surface to delete.
     */
    public function deleteSurface(_id : SurfaceID)
    {
        switch surfaces[_id]
        {
            case null:
                // Do nothing, surface does not exist.
            case surface:
                surface.surfaceView.release();
                surface.surfaceTexture.release();
                surface.surfaceRenderView.release();
                surface.depthStencilView.release();
                surface.depthStencilTexture.release();

                surfaces[_id] = null;
        }
    }
    
    public function updateTexture(_frame : PageFrameResource, _data : ArrayBufferView)
    {
        switch textureResources.get(_frame.page)
        {
            case null:
                throw new Exception('Page ${ _frame.page } does not exist');
            case texture:
                if (_data.byteLength != (_frame.width * _frame.height * 4))
                {
                    throw new Exception('Provided buffer does not match the frame byte size');
                }

                final box = new D3d11Box();
                box.left   = _frame.x;
                box.top    = _frame.y;
                box.front  = 0;
                box.right  = _frame.x + _frame.width;
                box.bottom = _frame.y + _frame.height;
                box.back   = 1;

                context.updateSubresource(texture.texture, 0, box, _data.buffer.getData(), _frame.width * 4, 0);
        }
    }

	function createShader(_resource : ShaderResource)
    {
        final shader = switch Std.downcast(_resource, D3d11Shader)
        {
            case null: throw new Exception('Shader resource is not D3d11Shader');
            case v: v;
        }

        if (shaderResources.exists(_resource.id))
        {
            throw new NotImplementedException('shader patching not yet implemented');
        }
        else
        {
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
    
            // Create a new input format one does not exist for the shaders input.
            // TODO : Reuse input layouts instead of creating a new one for each shader.
            var offset = 0;
    
            final layout = [];
    
            for (i in 0...shader.format.count)
            {
                final element = shader.format.get(i);
                final native  = new D3d11InputElementDescription();
                native.semanticName         = "TEXCOORD";
                native.semanticIndex        = element.location;
                native.format               = getInputFormat(element.type);
                native.inputSlot            = 0;
                native.alignedByteOffset    = offset;
                native.inputSlotClass       = PerVertexData;
                native.instanceDataStepRate = 0;
    
                offset += getInputFormatSize(element.type);
    
                layout.push(native);
            }
    
            final inputLayout = new D3d11InputLayout();
            if (device.createInputLayout(layout, vertexBytecode, inputLayout) != Ok)
            {
                throw new Exception('ID3D11InputLayout');
            }
    
            // Create our shader and a class to store its resources.
            shaderResources.set(_resource.id, new D3D11ShaderInformation(shader.vertBlocks, shader.fragBlocks, shader.textureCount, vertexShader, pixelShader, inputLayout, offset));
        }
    }

	function deleteShader(_id : ResourceID)
    {
        switch shaderResources.get(_id)
        {
            case null:
                // Shader does not exist.
            case shader:
                shader.inputLayout.release();
                shader.pixelShader.release();
                shader.vertexShader.release();

                shaderResources.remove(_id);
        }
    }

    function createTexture(_resource : PageResource)
    {
        if (textureResources.exists(_resource.id))
        {
            throw new NotImplementedException('Texture updating not implemented');
        }
        else
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
            imgDesc.bindFlags          = ShaderResource;
            imgDesc.cpuAccessFlags     = 0;
            imgDesc.miscFlags          = 0;
    
            final texture = new D3d11Texture2D();   
            if (device.createTexture2D(imgDesc, imgData, texture) != Ok)
            {
                throw new Exception('ID3D11Texture2D');
            }

            final shaderView = new D3d11ShaderResourceView();
            if (device.createShaderResourceView(texture, null, shaderView) != Ok)
            {
                throw new Exception('ID3D11ShaderResourceView');
            }
    
            textureResources.set(_resource.id, new D3D11TextureInformation(texture, shaderView));
        }
    }

    function deleteTexture(_id : ResourceID)
    {
        switch textureResources.get(_id)
        {
            case null:
                // Page does not exist.
            case texture:
                texture.shaderResourceView.release();
                texture.texture.release();

                textureResources.remove(_id);
        }
    }

    function createBackbufferSurface(_backbufferWidth : Int, _backbufferHeight : Int)
    {
        final swapchainTexture = new D3d11Texture2D();
        if (swapchain.getBuffer(0, NativeID3D11Texture2D.uuid(), swapchainTexture) != Ok)
        {
            throw new Exception('Failed to get swapchain buffer');
        }

        final backbufferRenderTargetView = new D3d11RenderTargetView();
        if (device.createRenderTargetView(swapchainTexture, null, backbufferRenderTargetView) != Ok)
        {
            throw new Exception('ID3D11RenderTargetView');
        }

        final depthTextureDesc = new D3d11Texture2DDescription();
        depthTextureDesc.width              = _backbufferWidth;
        depthTextureDesc.height             = _backbufferHeight;
        depthTextureDesc.mipLevels          = 1;
        depthTextureDesc.arraySize          = 1;
        depthTextureDesc.format             = D32FloatS8X24UInt;
        depthTextureDesc.sampleDesc.count   = 1;
        depthTextureDesc.sampleDesc.quality = 0;
        depthTextureDesc.usage              = Default;
        depthTextureDesc.bindFlags          = DepthStencil;
        depthTextureDesc.cpuAccessFlags     = 0;
        depthTextureDesc.miscFlags          = 0;

        final depthStencilTexture = new D3d11Texture2D();
        if (device.createTexture2D(depthTextureDesc, null, depthStencilTexture) != 0)
        {
            throw new Exception('ID3D11Texture2D');
        }

        final depthStencilViewDescription = new D3d11DepthStencilViewDescription();
        depthStencilViewDescription.format             = D32FloatS8X24UInt;
        depthStencilViewDescription.viewDimension      = Texture2D;
        depthStencilViewDescription.texture2D.mipSlice = 0;

        final depthStencilView = new D3d11DepthStencilView();
        if (device.createDepthStencilView(depthStencilTexture, depthStencilViewDescription, depthStencilView) != 0)
        {
            throw new Exception('ID3D11DepthStencilView');
        }

        surfaces[SurfaceID.backbuffer] =
            new D3D11SurfaceInformation(
                { width : _backbufferWidth, height : _backbufferHeight },
                swapchainTexture,
                null,
                backbufferRenderTargetView,
                depthStencilTexture,
                depthStencilView);
    }

    function getNextPipelineID()
    {
        for (i in 0...pipelines.length)
        {
            if (pipelines[i] == null)
            {
                return i;
            }
        }

        throw new Exception('Maximum number of pipelines met');
    }

    function getNextSurfaceID()
    {
        for (i in 0...surfaces.length)
        {
            if (surfaces[i] == null)
            {
                return i;
            }
        }

        throw new Exception('Maximum number of surfaces met');
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

        final backbuffer = surfaces[SurfaceID.backbuffer];

        backbuffer.surfaceTexture.release();
        backbuffer.surfaceRenderView.release();
        backbuffer.depthStencilView.release();
        backbuffer.depthStencilTexture.release();

        if (swapchain.resizeBuffers(0, _width, _height, Unknown, 0) != Ok)
        {
            throw new Exception('Failed to resize swapchain');
        }

        createBackbufferSurface(_width, _height);
    }
}