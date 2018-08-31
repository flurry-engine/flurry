package uk.aidanlee.gpu.backend;

import haxe.io.Bytes;
import haxe.ds.Map;

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
import snow.api.buffers.Uint8Array;
import snow.api.Debug.def;
import uk.aidanlee.gpu.Renderer.RendererOptions;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderType;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderLayout;
import uk.aidanlee.gpu.batcher.DrawCommand;
import uk.aidanlee.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.gpu.geometry.Geometry.PrimitiveType;
import uk.aidanlee.gpu.geometry.Geometry.BlendMode;
import uk.aidanlee.gpu.IRenderTarget;
import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.maths.Matrix;

using cpp.Pointer;

@:headerCode('
#include <D3Dcompiler.h>
#include "SDL_syswm.h"
')
class DX11Backend implements IRendererBackend
{
    /**
     * Access to the renderer which owns this backend.
     */
    final renderer : Renderer;

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
     * The backbuffer everything is drawn to by default.
     */
    var backbuffer : RenderTargetView;

    /**
     * Single main vertex buffer.
     */
    var vertexBuffer : Buffer;

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
    var defaultTarget : IRenderTarget;

    /**
     * Map of shader name to the D3D11 resources required to use the shader.
     */
    var shaderResources : Map<Int, DXShaderInformation>;

    /**
     * Sequence number shader IDs.
     * For each generated shader this number is incremented and given to the shader as a unique ID.
     * Allows batchers to sort shaders.
     */
    var shaderSequence : Int;

    /**
     * Map of texture name to the D3D11 resources required to use the texture.
     */
    var textureResources : Map<Int, DXTextureInformation>;

    /**
     * Sequence number texture IDs.
     * For each generated texture this number is incremented and given to the texture as a unique ID.
     * Allows batchers to sort textures.
     */
    var textureSequence : Int;

    /**
     * Map of target IDs to the D3D11 resources required to use the target.
     */
    var targetResources : Map<Int, DXTargetInformation>;

    /**
     * Sequence number render texture IDs.
     * For each generated render texture this number is incremented and given to the render texture as a unique ID.
     * Allows batchers to sort render textures.
     */
    var targetSequence : Int;

    /**
     * Current float offset for writing into the vertex buffer.
     */
    var floatOffset : Int;

    /**
     * Current vertex offset for writing into the vertex buffer.
     */
    var vertexOffset : Int;

    // State trackers
    var viewport : Rectangle;
    var scissor  : Rectangle;
    var topology : PrimitiveType;
    var target   : IRenderTarget;
    var shader   : Shader;
    var texture  : Texture;

    public function new(_renderer : Renderer, _options : RendererOptions)
    {
        _options.backend = def(_options.backend, {});

        var success    = false;
        var adapterIdx = 0;
        var outputIdx  = 0;
        var wind : sdl.Window.Window = _options.backend.window;
        var hwnd : com.HWND          = null;

        untyped __cpp__('SDL_SysWMinfo info;
        SDL_VERSION(&info.version);
        SDL_GetWindowWMInfo({1}, &info);
        {0} = SDL_DXGIGetOutputInfo(SDL_GetWindowDisplayIndex({1}), &{2}, &{3});
        {4} = info.info.win.window', success, wind, adapterIdx, outputIdx, hwnd);

        if (!success)
        {
            throw 'Unable to get DXGI information for the main SDL window';
        }

        renderer = _renderer;

        shaderSequence  = 0;
        shaderResources = new Map();

        textureSequence  = 0;
        textureResources = new Map();

        targetSequence = 0;
        targetResources = new Map();

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
        description.bufferDescription.width  = _options.width;
        description.bufferDescription.height = _options.height;
        description.bufferDescription.format = R8G8B8A8_UNORM;
        description.sampleDescription.count  = 1;
        description.outputWindow = hwnd;
        description.bufferCount  = 1;
        description.bufferUsage  = DXGI.USAGE_RENDER_TARGET_OUTPUT;
        description.windowed     = true;

        // Create our actual device and swapchain
        if (D3D11.createDevice(adapter, cast device.addressOf(), cast context.addressOf()) != 0)
        {
            throw 'Failed to create D3D11 device';
        }
        if (factory.createSwapChain(device, cast description.addressOf(), cast swapchain.addressOf()) != 0)
        {
            throw 'Failed to create DXGI swapchain';
        }

        // Release now un-needed DXGI resources
        factory.release();
        adapter.release();
        output.release();

        // Create the backbuffer render target.
        var texture : Texture2D = null;
        if (swapchain.getBuffer(0, cast texture.addressOf()) != 0)
        {
            throw 'Failed to get swapchain backbuffer';
        }
        if (device.createRenderTargetView(texture, null, cast backbuffer.addressOf()) != 0)
        {
            throw 'Failed to create render target view from backbuffer';
        }
        texture.release();

        // Create the default viewport
        nativeView = Viewport.create();
        nativeView.topLeftX = 0;
        nativeView.topLeftY = 0;
        nativeView.width    = _options.width;
        nativeView.height   = _options.height;

        // Create the default clip
        nativeClip = Rect.create();
        nativeClip.top    = 0;
        nativeClip.left   = 0;
        nativeClip.right  = _options.width;
        nativeClip.bottom = _options.height;

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
            throw 'Failed to create rasterizer state';
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
            throw 'Unable to create blend state';
        }

        // Create our (initially) empty vertex buffer.
        var bufferDesc = BufferDescription.create();
        bufferDesc.byteWidth      = (_options.maxDynamicVertices + _options.maxUnchangingVertices) * 9;
        bufferDesc.usage          = DYNAMIC;
        bufferDesc.bindFlags      = VERTEX_BUFFER;
        bufferDesc.cpuAccessFlags = WRITE;

        if (device.createBuffer(cast bufferDesc.addressOf(), null, cast vertexBuffer.addressOf()) != 0)
        {
            throw 'Failed to create vertex buffer';
        }

        // Create a representation of the backbuffer and manually insert it into 
        defaultTarget = new BackBuffer(targetSequence, _options.width, _options.height, _options.dpi);

        var resource = new DXTargetInformation();
        resource.rtv = backbuffer;
        targetResources.set(targetSequence, resource);

        targetSequence++;

        // Set the initial context state.
        var stride = (9 * 4);
        var offset = 0;
        context.iaSetVertexBuffers(0, [ vertexBuffer ], [ stride ], [ offset ]);
        context.iaSetPrimitiveTopology(TRIANGLELIST);
        context.rsSetViewports([ nativeView ]);
        context.rsSetScissorRects([ nativeClip ]);
        context.rsSetState(rasterState);

        floatOffset  = 0;
        vertexOffset = 0;
        transformationVector = new Vector();
        dynamicCommandRanges = new Map();

        // Setup initial state tracker
        viewport = new Rectangle(0, 0, _options.width, _options.height);
        scissor  = new Rectangle(0, 0, _options.width, _options.height);
        topology = PrimitiveType.Triangles;
        target   = null;
        shader   = null;
        texture  = null;
    }

    public function clear()
    {
        context.clearRenderTargetView(backbuffer, [ 0.2, 0.2, 0.2, 1.0 ]);
    }

    public function clearUnchanging()
    {
        //
    }

    public function preDraw()
    {
        floatOffset  = 0;
        vertexOffset = 0;
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void
    {
        // Map the buffer.
        var mappedBuffer = MappedSubResource.create();
        if (context.map(vertexBuffer, 0, WRITE_DISCARD, 0, cast mappedBuffer.addressOf()) != 0)
        {
            throw 'Failed to map vertex buffer';
        }

        // Get a buffer to float32s so we can copy our float32array over.
        var ptr : Pointer<cpp.Float32> = Pointer.fromRaw(mappedBuffer.sysMem).reinterpret();

        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset));

            for (geom in command.geometry)
            {
                var matrix = geom.transformation.transformation;

                for (vertex in geom.vertices)
                {
                    // Copy the vertex into another vertex.
                    // This allows us to apply the transformation without permanently modifying the original geometry.
                    transformationVector.copyFrom(vertex.position);
                    transformationVector.transform(matrix);

                    ptr[floatOffset++] = transformationVector.x;
                    ptr[floatOffset++] = transformationVector.y;
                    ptr[floatOffset++] = transformationVector.z;
                    ptr[floatOffset++] = vertex.color.r;
                    ptr[floatOffset++] = vertex.color.g;
                    ptr[floatOffset++] = vertex.color.b;
                    ptr[floatOffset++] = vertex.color.a;
                    ptr[floatOffset++] = vertex.texCoord.x;
                    ptr[floatOffset++] = vertex.texCoord.y;

                    vertexOffset++;
                }
            }
        }

        context.unmap(vertexBuffer, 0);
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
            throw 'Failed to map vertex buffer';
        }

        // Get a buffer to float32s so we can copy our float32array over.
        var ptr : Pointer<cpp.Float32> = Pointer.fromRaw(mappedBuffer.sysMem).reinterpret();

        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset));

            for (i in command.startIndex...command.endIndex)
            {
                ptr[floatOffset++] = command.buffer[i];
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
            context.draw(range.vertices, range.vertexOffset);

            // Record stats
            if (_recordStats)
            {
                renderer.stats.dynamicDraws++;
                renderer.stats.totalVertices += command.vertices;
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
        backbuffer.release();

        if (swapchain.resizeBuffers(0, _width, _height, DXGI_FORMAT.UNKNOWN, 0) != 0)
        {
            throw 'Unable to resize the swapchain';
        }

        // Create a texture target from the backbuffer
        var texture : Texture2D = null;

        if (swapchain.getBuffer(0, cast texture.addressOf()) != 0)
        {
            throw 'Failed to get swapchain backbuffer';
        }
        if (device.createRenderTargetView(texture, null, cast backbuffer.addressOf()) != 0)
        {
            throw 'Failed to create render target view from backbuffer';
        }

        // Release the temp texture and set the backbuffer to our filled out buffer.
        // Not sure why we need the temp buffer, doesn't work without it.
        texture.release();

        // Update the default backbuffer representation with the pointer.
        var resource = targetResources.get(0);
        resource.rtv = backbuffer;

        // If we don't force a render target change here then the previous backbuffer pointer might still be bound and used.
        // This would cause nothing to render since that old backbuffer has now been released.
        context.omSetRenderTargets([ resource.rtv], null);
        target = defaultTarget;
        renderer.stats.targetSwaps++;
    }

    /**
     * Release all DX11 interface pointers.
     */
    public function cleanup()
    {
        for (shader in shaderResources.keys())
        {
            removeShader(shader);
        }

        for (texture in textureResources.keys())
        {
            removeTexture(texture);
        }

        for (target in targetResources.keys())
        {
            removeRenderTarget(target);
        }

        rasterState.release();
        blendState.release();
        vertexBuffer.release();

        backbuffer.release();
        swapchain.release();
        context.release();
        device.release();
    }

    // #region resource handling

    /**
     * Create the D3D11 resources required for a shader.
     * @param _vert   Vertex source.
     * @param _frag   Pixel source.
     * @param _layout JSON shader layout description.
     * @return Shader
     */
    public function createShader(_vert : String, _frag : String, _layout : ShaderLayout) : Shader
    {
        // Compile the HLSL vertex shader
        var vertexBytecode : Blob = null;
        var vertexErrors   : Blob = null;
        if (D3DCompiler.compile(_vert, "VShader", "vs_4_0", cast vertexBytecode.addressOf(), cast vertexErrors.addressOf()) != 0)
        {
            throw 'Unable to compile vertex shader';
        }

        // Compile the HLSL pixel shader
        var pixelBytecode : Blob = null;
        var pixelErrors   : Blob = null;
        if (D3DCompiler.compile(_frag, "PShader", "ps_4_0", cast pixelBytecode.addressOf(), cast pixelErrors.addressOf()) != 0)
        {
            throw 'Unable to compile fragment shader';
        }

        // Create the vertex shader
        var vertexShader : VertexShader = null;
        if (device.createVertexShader(vertexBytecode.getBufferPointer(), vertexBytecode.getBufferSize(), null, cast vertexShader.addressOf()) != 0)
        {
            throw 'Unable to create vertex shader';
        }

        // Create the fragment shader
        var pixelShader : PixelShader = null;
        if (device.createPixelShader(pixelBytecode.getBufferPointer(), pixelBytecode.getBufferSize(), null, cast pixelShader.addressOf()) != 0)
        {
            throw 'Unable to create vertex shader';
        }

        // Create an input layout.
        var inputDescriptor = InputElementDescriptionArray.create();
        inputDescriptor.add("POSITION", 0, R32G32B32_FLOAT   , 0,  0, PER_VERTEX_DATA, 0);
        inputDescriptor.add("COLOR"   , 0, R32G32B32A32_FLOAT, 0, 12, PER_VERTEX_DATA, 0);
        inputDescriptor.add("TEXCOORD", 0, R32G32_FLOAT      , 0, 28, PER_VERTEX_DATA, 0);

        var inputLayout : InputLayout = null;
        if (device.createInputLayout(inputDescriptor, vertexBytecode.getBufferPointer(), vertexBytecode.getBufferSize(), cast inputLayout.addressOf()) != 0)
        {
            throw 'Error creating input layout';
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
            throw 'Failed to create default cbuffer';
        }

        // Create our shader and a class to store its resources.
        var resource = new DXShaderInformation();
        resource.layout  = _layout;
        resource.vertex  = vertexShader;
        resource.pixel   = pixelShader;
        resource.input   = inputLayout;

        resource.bytes   = [];
        resource.buffers = new Map();
        resource.buffers.set(0, defaultBuffer);
        
        // Create a D3D cbuffer for each of our user defined blocks
        for (i in 0..._layout.blocks.length)
        {
            var bytesSize = 0;
            for (val in _layout.blocks[i].vals)
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
                throw 'Failed to create default cbuffer';
            }

            resource.buffers.set(i + 1, cast buffer);
            resource.bytes.push(bytesData);
        }

        shaderResources.set(shaderSequence, resource);

        return new Shader(shaderSequence++);
    }

    /**
     * Remove the D3D11 resources used by a shader.
     * @param _name Name of the shader to remove.
     */
    public function removeShader(_id : Int)
    {
        var resources = shaderResources.get(_id);

        resources.vertex.release();
        resources.pixel.release();
        resources.input.release();

        for (buffer in resources.buffers)
        {
            buffer.release();
        }

        shaderResources.remove(_id);
    }

    /**
     * Create the D3D11 resources needed for a texture.
     * @param _pixels Raw image RGBA data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
    public function createTexture(_pixels : Uint8Array, _width : Int, _height : Int) : Texture
    {
        var imgByte = _pixels.toBytes().getData();

        // Sub resource struct to hold the raw image bytes.
        var imgData = SubResourceData.create();
        imgData.sysMem           = untyped __cpp__('(const void *)&({0}[0])', imgByte);
        imgData.sysMemPitch      = 4 * _width;
        imgData.sysMemSlicePitch = 0;

        // Texture description struct. Describes how our raw image data is formated and usage of the texture.
        var imgDesc = Texture2DDescription.create();
        imgDesc.width     = _width;
        imgDesc.height    = _height;
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
            throw 'Failed to create Texture2D';
        }
        if (device.createShaderResourceView(img, null, cast srv.addressOf()) != 0)
        {
            throw 'Failed to create shader resource view';
        }
        if (device.createSamplerState(samplerDescription, cast smp.addressOf()) != 0)
        {
            throw 'Failed to create sampler state';
        }

        var resource = new DXTextureInformation();
        resource.tex = img;
        resource.srv = srv;
        resource.smp = smp;

        textureResources.set(textureSequence, resource);

        return new Texture(textureSequence++, _width, _height);
    }

    /**
     * Free the D3D11 resources used by a texture.
     * @param _name Name of the texture to remove.
     */
    public function removeTexture(_id : Int)
    {
        var resources = textureResources.get(_id);

        resources.srv.release();
        resources.tex.release();
        resources.smp.release();

        textureResources.remove(_id);
    }

    /**
     * Create the D3D11 resources needed for a render texture.
     * @param _width  Render texture width.
     * @param _height Render texture height.
     * @return RenderTexture
     */
    public function createRenderTarget(_width : Int, _height : Int) : RenderTexture
    {
        var imgDesc = Texture2DDescription.create();
        imgDesc.width     = _width;
        imgDesc.height    = _height;
        imgDesc.mipLevels = 1;
        imgDesc.arraySize = 1;
        imgDesc.format    = R8G8B8A8_UNORM;
        imgDesc.sampleDesc.count   = 1;
        imgDesc.sampleDesc.quality = 0;
        imgDesc.usage          = DEFAULT;
        imgDesc.bindFlags      = SHADER_RESOURCE;
        imgDesc.cpuAccessFlags = 0;
        imgDesc.miscFlags      = 0;

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
        var rtv : RenderTargetView   = null;
        var smp : SamplerState       = null;

        if (device.createTexture2D(cast imgDesc.addressOf(), null, cast img.addressOf()) != 0)
        {
            throw 'Failed to create Texture2D';
        }
        if (device.createShaderResourceView(img, null, cast srv.addressOf()) != 0)
        {
            throw 'Failed to create shader resource view';
        }
        if (device.createRenderTargetView(img, null, cast rtv.addressOf()) != 0)
        {
            throw 'Failed to create render target view';
        }
        if (device.createSamplerState(samplerDescription, cast smp.addressOf()) != 0)
        {
            throw 'Failed to create sampler state';
        }

        var resource = new DXTargetInformation();
        resource.tex = img;
        resource.srv = srv;
        resource.rtv = rtv;
        resource.smp = smp;

        targetResources.set(targetSequence, resource);

        return new RenderTexture(targetSequence++, textureSequence++, _width, _height, 1);
    }

    /**
     * Release the D3D resources used by a render texture.
     * @param _target Render texture to remove.
     */
    public function removeRenderTarget(_targetID : Int)
    {
        var resources = targetResources.get(_targetID);

        resources.srv.release();
        resources.tex.release();
        resources.rtv.release();
        resources.smp.release();

        targetResources.remove(_targetID);
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
        var cmdView = _command.viewport != null ? _command.viewport : new Rectangle(0, 0, defaultTarget.width, defaultTarget.height);
        if (!viewport.equals(cmdView))
        {
            viewport.copyFrom(cmdView);

            nativeView.topLeftX = viewport.x;
            nativeView.topLeftY = viewport.y;
            nativeView.width    = viewport.w;
            nativeView.height   = viewport.h;
            context.rsSetViewports([ nativeView ]);

            renderer.stats.viewportSwaps++;
        }

        // Update scissor
        var cmdClip = _command.clip != null ? _command.clip : new Rectangle(0, 0, defaultTarget.width, defaultTarget.height);
        if (!scissor.equals(cmdClip))
        {
            scissor.copyFrom(cmdClip);

            nativeClip.left   = cast scissor.x;
            nativeClip.top    = cast scissor.y;
            nativeClip.right  = cast scissor.w;
            nativeClip.bottom = cast scissor.h;
            context.rsSetScissorRects([ nativeClip ]);

            renderer.stats.scissorSwaps++;
        }

        // Set the render target
        var cmdTarget  = _command.target != null ? _command.target : defaultTarget;
        if (cmdTarget != target)
        {
            var resource = targetResources.get(cmdTarget.targetID);
            context.omSetRenderTargets([ resource.rtv ], null);

            target = cmdTarget;

            renderer.stats.targetSwaps++;
        }

        // Always update the cbuffers and textures for now
        setShaderValues(_command);

        // Write shader cbuffers and set it
        if (shader != _command.shader)
        {
            shader = _command.shader;

            // Apply the actual shader and input layout.
            var shaderResource = shaderResources.get(_command.shader.shaderID);

            context.iaSetInputLayout(shaderResource.input);
            context.vsSetShader(shaderResource.vertex, null, 0);
            context.psSetShader(shaderResource.pixel , null, 0);

            renderer.stats.shaderSwaps++;
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

        if (device.createBlendState(blendDescription, cast blendState.addressOf()) != 0)
        {
            throw 'Unable to create blend state';
        }
        context.omSetBlendState(blendState, [ 1, 1, 1, 1 ], 0xffffffff);

        renderer.stats.blendSwaps++;

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
        var shaderResource = shaderResources.get(_command.shader.shaderID);

        // Set all textures.
        if (shaderResource.layout.textures.length > _command.textures.length)
        {
            throw 'Error : More textures required by the shader than are provided by the draw command';
        }
        else
        {
            for (i in 0...shaderResource.layout.textures.length)
            {
                var textureResource = textureResources.get(_command.textures[i].textureID);
                context.psSetShaderResources(i, [ textureResource.srv ]);
                context.psSetSamplers(i, [ textureResource.smp ]);

                renderer.stats.textureSwaps++;
            }
        }

        // Update our default cbuffer since its values are retreived from the command and not shader class.

        var map = MappedSubResource.create();
        if (context.map(shaderResource.buffers.get(0), 0, WRITE_DISCARD, 0, map) != 0)
        {
            throw 'Failed to map default shader cbuffer';
        }

        var ptr : Pointer<cpp.Float32> = map.sysMem.fromRaw().reinterpret();
        var itr = 0;

        for (el in _command.projection.elements)
        {
            ptr[itr++] = el;
        }
        for (el in _command.view.elements)
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
                    case Matrix4: bytePosition += writeMatrix4(shaderResource.bytes[i], bytePosition, _command.shader.matrix4.get(val.name));
                    case Vector4: bytePosition += writeVector4(shaderResource.bytes[i], bytePosition, _command.shader.vector4.get(val.name));
                    case Int    : bytePosition +=     writeInt(shaderResource.bytes[i], bytePosition, _command.shader.int.get(val.name));
                }
            }

            // Map and memcpy the bytes to the subresource data.
            var map = MappedSubResource.create();
            if (context.map(shaderResource.buffers.get(i + 1), 0, WRITE_DISCARD, 0, map) != 0)
            {
                throw 'Failed to map default shader cbuffer';
            }

            // TODO : Look into memcpy to simplify this code.
            var ptr : Pointer<cpp.UInt8> = map.sysMem.fromRaw().reinterpret();
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
        for (el in _matrix.elements)
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

private class DrawCommandRange
{
    public final vertices : Int;

    public final vertexOffset : Int;

    inline public function new(_vertices : Int, _vertexOffset : Int)
    {
        vertices     = _vertices;
        vertexOffset = _vertexOffset;
    }
}
