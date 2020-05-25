package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import haxe.Exception;
import haxe.io.BytesData;
import haxe.io.Bytes;
import haxe.ds.ReadOnlyArray;
import cpp.Stdlib.memcpy;
import sdl.Window;
import sdl.GLContext;
import sdl.SDL;
import glad.Glad;
import opengl.GL.*;
import opengl.WebGL.getShaderParameter;
import opengl.WebGL.shaderSource;
import opengl.WebGL.getProgramParameter;
import opengl.WebGL.getProgramInfoLog;
import opengl.WebGL.getShaderInfoLog;
import rx.disposables.ISubscription;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererOgl3Config;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderBlock;
import uk.aidanlee.flurry.api.resources.ResourceEvents;

using rx.Observable;
using cpp.NativeArray;
using uk.aidanlee.flurry.api.gpu.backend.OGLUtils;

class OGL3Backend implements IRendererBackend
{
    /**
     * The number of floats in each vertex.
     */
    static final VERTEX_BYTE_SIZE = 36;

    /**
     * The byte offset for the position in each vertex.
     */
    static final VERTEX_OFFSET_POS = 0;

    /**
     * The byte offset for the colour in each vertex.
     */
    static final VERTEX_OFFSET_COL = 12;

    /**
     * The byte offset for the texture coordinates in each vertex.
     */
    static final VERTEX_OFFSET_TEX = 28;

    /**
     * Number of bytes in a 4x4 float matrix
     */
    static final BYTES_PER_MATRIX = 4 * 4 * 4;

    /**
     * Number of bytes needed to store the model, view, and projection matrix for each draw command.
     */
    static final BYTES_PER_DRAW_MATRICES = 4 * 4 * 4 * 3;

    /**
     * Signals for when shaders and images are created and removed.
     */
    final resourceEvents : ResourceEvents;

    /**
     * Signals for when a window change has been requested and dispatching back the result.
     */
    final displayEvents : DisplayEvents;

    /**
     * The single VBO used by the backend.
     */
    final glVertexBuffer : Int;

    /**
     * The single index buffer used by the backend.
     */
    final glIndexbuffer : Int;

    /**
     * The ubo used to store all matrix data.
     */
    final glMatrixBuffer : Int;

    /**
     * The ubo used to store all uniform data.
     */
    final glUniformBuffer : Int;

    /**
     * Vertex buffer used by this backend.
     */
    final vertexBuffer : BytesData;

    /**
     * Index buffer used by this backend.
     */
    final indexBuffer : BytesData;

    /**
     * Buffer used to store model, view, and projection matrices for all draws.
     */
    final matrixBuffer : BytesData;

    /**
     * Buffer used to store all uniform data for draws.
     */
    final uniformBuffer : BytesData;

    /**
     * Shader programs keyed by their associated shader resource IDs.
     */
    final shaderPrograms : Map<String, Int>;

    /**
     * Shader uniform locations keyed by their associated shader resource IDs.
     */
    final shaderUniforms : Map<String, ShaderLocations>;

    /**
     * Texture objects keyed by their associated image resource IDs.
     */
    final textureObjects : Map<String, Int>;

    /**
     * The sampler objects which have been created for each specific texture.
     */
    final samplerObjects : Map<String, Map<Int, Int>>;

    /**
     * Framebuffer objects keyed by their associated image resource IDs.
     * Framebuffers will only be generated when an image resource is used as a target.
     * Will be destroyed when the associated image resource is destroyed.
     */
    final framebufferObjects : Map<String, Int>;

    /**
     * Array of opengl textures objects which are bound.
     * Size of this array is equal to the max number of texture bindings allowed.
     */
    final textureSlots : Array<Int>;

    /**
     * Array of opengl sampler objects which are bound.
     * Size of this array is equal to the max number of texture bindings allowed.
     */
    final samplerSlots : Array<Int>;

    /**
     * The default sampler object to use if no sampler is provided.
     */
    final defaultSampler : Int;

    /**
     * The bytes alignment for ubos.
     */
    final glUboAlignment : Int;

    /**
     * Number of bytes for each mvp matrix range.
     * Includes padding for ubo alignment.
     */
    final matrixRangeSize : Int;

    /**
     * All the commands queued for uploading and drawing.
     */
    final commandQueue : Array<DrawCommand>;

    final resourceCreatedSubscription : ISubscription;

    final resourceRemovedSubscription : ISubscription;

    final displaySizeChangedSubscription : ISubscription;

    final displayChangeRequestSubscription : ISubscription;

    /**
     * Backbuffer display, default target if none is specified.
     */
    var backbuffer : BackBuffer;

    // GL state variables
    // Making redundent GL state changes can be very expensive
    // Querying the current state with glGet is also very expensive
    // So we track the current state with the equivilent flurry sturctures.

    var target     : TargetState;
    var shader     : ShaderResource;
    final clip     : Rectangle;
    final viewport : Rectangle;
    final blend    : BlendState;
    final depth    : DepthState;
    final stencil  : StencilState;

    // SDL Window and GL Context

    var window : Window;

    var glContext : GLContext;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererOgl3Config)
    {
        resourceEvents = _resourceEvents;
        displayEvents  = _displayEvents;

        createWindow(_windowConfig);

        shaderPrograms     = [];
        shaderUniforms     = [];
        textureObjects     = [];
        samplerObjects     = [];
        framebufferObjects = [];

        // Create and bind a singular VBO.
        // Only needs to be bound once since it is used for all drawing.
        vertexBuffer  = Bytes.alloc(_rendererConfig.vertexBufferSize ).getData();
        indexBuffer   = Bytes.alloc(_rendererConfig.indexBufferSize  ).getData();
        matrixBuffer  = Bytes.alloc(_rendererConfig.matrixBufferSize ).getData();
        uniformBuffer = Bytes.alloc(_rendererConfig.uniformBufferSize).getData();

        // Core OpenGL profiles require atleast one VAO is bound.
        var vao = [ 0 ];
        glGenVertexArrays(1, vao);
        glBindVertexArray(vao[0]);

        // Create two vertex buffers
        var vbos = [ 0, 0, 0, 0 ];
        glGenBuffers(vbos.length, vbos);
        glVertexBuffer  = vbos[0];
        glIndexbuffer   = vbos[1];
        glMatrixBuffer  = vbos[2];
        glUniformBuffer = vbos[3];

        // Allocate the matrix buffer.
        glBindBuffer(GL_UNIFORM_BUFFER, glMatrixBuffer);
        glBufferData(GL_UNIFORM_BUFFER, matrixBuffer.length, matrixBuffer, GL_DYNAMIC_DRAW);

        glBindBuffer(GL_UNIFORM_BUFFER, glUniformBuffer);
        glBufferData(GL_UNIFORM_BUFFER, uniformBuffer.length, uniformBuffer, GL_DYNAMIC_DRAW);

        // Vertex data will be interleaved, sourced from the first vertex buffer.
        glBindBuffer(GL_ARRAY_BUFFER, glVertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, vertexBuffer.length, vertexBuffer, GL_DYNAMIC_DRAW);

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);

        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 0, 3, GL_FLOAT, false, VERTEX_BYTE_SIZE, VERTEX_OFFSET_POS);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 1, 4, GL_FLOAT, false, VERTEX_BYTE_SIZE, VERTEX_OFFSET_COL);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 2, 2, GL_FLOAT, false, VERTEX_BYTE_SIZE, VERTEX_OFFSET_TEX);

        // Setup index buffer.
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIndexbuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBuffer.length, indexBuffer, GL_DYNAMIC_DRAW);

        var samplers = [ 0 ];
        glGenSamplers(1, samplers);
        defaultSampler = samplers[0];
        glSamplerParameteri(defaultSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // default state
        viewport     = new Rectangle();
        clip         = new Rectangle();
        blend        = new BlendState();
        depth        = {
            depthTesting  : false,
            depthMasking  : false,
            depthFunction : Always
        };
        stencil      = {
            stencilTesting : false,

            stencilFrontMask          : 0xff,
            stencilFrontFunction      : Always,
            stencilFrontTestFail      : Keep,
            stencilFrontDepthTestFail : Keep,
            stencilFrontDepthTestPass : Keep,
            
            stencilBackMask          : 0xff,
            stencilBackFunction      : Always,
            stencilBackTestFail      : Keep,
            stencilBackDepthTestFail : Keep,
            stencilBackDepthTestPass : Keep
        };
        shader       = null;
        target       = Backbuffer;
        textureSlots = [ for (_ in 0...GL_MAX_TEXTURE_IMAGE_UNITS) 0 ];
        samplerSlots = [ for (_ in 0...GL_MAX_TEXTURE_IMAGE_UNITS) 0 ];

        // Create our own custom backbuffer.
        // we blit a flipped version to the actual backbuffer before swapping.
        backbuffer = createBackbuffer(_windowConfig.width, _windowConfig.height, false);

        // Default blend mode
        // Blend equation is not currently changable
        glEnable(GL_BLEND);
        glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);

        // Set the clear colour
        glClearColor(_rendererConfig.clearColour.x, _rendererConfig.clearColour.y, _rendererConfig.clearColour.z, _rendererConfig.clearColour.w);

        // Default scissor test
        glEnable(GL_SCISSOR_TEST);

        updateClip(0, 0, backbuffer.width, backbuffer.height);
        updateViewport(0, 0, backbuffer.width, backbuffer.height);
        updateDepth(depth);
        updateStencil(stencil);

        resourceCreatedSubscription = resourceEvents.created.subscribeFunction(onResourceCreated);
        resourceRemovedSubscription = resourceEvents.removed.subscribeFunction(onResourceRemoved);

        displaySizeChangedSubscription   = displayEvents.sizeChanged.subscribeFunction(onSizeChanged);
        displayChangeRequestSubscription = displayEvents.changeRequested.subscribeFunction(onChangeRequest);

        var uboAlignment = [ 0 ];
        glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, uboAlignment);

        glUboAlignment  = uboAlignment[0];
        matrixRangeSize = BYTES_PER_DRAW_MATRICES + Std.int(Maths.max(glUboAlignment - BYTES_PER_DRAW_MATRICES, 0));
        commandQueue    = [];
    }

    /**
     * Queue a command to be drawn this frame.
     * @param _command Command to draw.
     */
    public function queue(_command : DrawCommand)
    {
        commandQueue.push(_command);
    }

    /**
     * Uploads all data to the gpu then issues draw calls for all queued commands.
     */
    public function submit()
    {
        target = Backbuffer;
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

        // Upload and draw all commands
        uploadGeometryData();
        uploadMatrixData();
        uploadUniformData();
        drawCommands();

        // Once all commands have been drawn we blit and vertically flip our custom backbuffer into the windows backbuffer.
        // We then call the SDL function to swap the window.
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, backbuffer.framebuffer);

        updateClip(0, 0, backbuffer.width, backbuffer.height);
        glBlitFramebuffer(
            0, 0, backbuffer.width, backbuffer.height,
            0, backbuffer.height, backbuffer.width, 0,
            GL_COLOR_BUFFER_BIT, GL_NEAREST);

        glBindFramebuffer(GL_FRAMEBUFFER, backbuffer.framebuffer);

        SDL.GL_SwapWindow(window);

        commandQueue.resize(0);
    }

    /**
     * Unmap the buffer and iterate over all resources deleting their resources and remove them from the structure.
     */
    public function cleanup()
    {
        resourceCreatedSubscription.unsubscribe();
        resourceRemovedSubscription.unsubscribe();

        displaySizeChangedSubscription.unsubscribe();
        displayChangeRequestSubscription.unsubscribe();

        for (_ => shader in shaderPrograms)
        {
            glDeleteProgram(shader);
        }

        for (_ => texture in textureObjects)
        {
            glDeleteTextures(1, [ texture ]);
        }

        for (_ => samplers in samplerObjects)
        {
            for (_ => sampler in samplers)
            {
                glDeleteSamplers(1, [ sampler ]);
            }
        }

        for (_ => framebuffer in framebufferObjects)
        {
            glDeleteFramebuffers(1, [ framebuffer ]);
        }

        glDeleteFramebuffers(1, [ backbuffer.framebuffer ]);

        shaderPrograms.clear();
        shaderUniforms.clear();
        textureObjects.clear();
        samplerObjects.clear();
        framebufferObjects.clear();

        SDL.GL_DeleteContext(glContext);
        SDL.destroyWindow(window);
    }

    // #region SDL Window Management

    /**
     * Create an SDL window and request a core 3.3 openGL context with it.
     * Then bind that content to the current thread.
     * GLAD is used to load all OpenGL functions with the SDL process address function.
     * @param _options Initial window options.
     */
    function createWindow(_options : FlurryWindowConfig)
    {        
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        window    = SDL.createWindow(_options.title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
        glContext = SDL.GL_CreateContext(window);

        SDL.GL_MakeCurrent(window, glContext);

        if (Glad.gladLoadGLLoader(untyped __cpp__('&SDL_GL_GetProcAddress')) == 0)
        {
            throw new OGL3FailedToLoad();
        }
    }

    /**
     * When a size request comes in we call the appropriate SDL functions to set the size and state of the window and swap interval.
     * We do not re-create the backbuffer here as resizing may fail for some reason.
     * When a resize it successful a size changed event will be published through the engine which we listen to and resize the backbuffer then.
     * @param _event Event containing the request details.
     */
    function onChangeRequest(_event : DisplayEventChangeRequest)
    {
        SDL.setWindowSize(window, _event.width, _event.height);
        SDL.setWindowFullscreen(window, _event.fullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
        SDL.GL_SetSwapInterval(_event.vsync ? 1 : 0);
    }

    /**
     * When the window has been resized we need to recreate our backbuffer representation to match the new size.
     * Since our backbuffer is custom we can't just update the viewport and be done.
     * @param _event Event containing the new window size.
     */
    function onSizeChanged(_event : DisplayEventData)
    {
        backbuffer = createBackbuffer(_event.width, _event.height);
    }

    // #endregion

    // #region Resource Management

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

    function createShader(_resource : ShaderResource)
    {
        if (shaderPrograms.exists(_resource.id))
        {
            return;
        }

        if (_resource.ogl3 == null)
        {
            throw new OGL3NoShaderSourceException(_resource.id);
        }

        // Create vertex shader.
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        shaderSource(vertex, _resource.ogl3.vertex.toString());
        glCompileShader(vertex);

        if (getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw new OGL3VertexCompilationError(_resource.id, getShaderInfoLog(vertex));
        }

        // Create fragment shader.
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        shaderSource(fragment, _resource.ogl3.fragment.toString());
        glCompileShader(fragment);

        if (getShaderParameter(fragment, GL_COMPILE_STATUS) == 0)
        {
            throw new OGL3FragmentCompilationError(_resource.id, getShaderInfoLog(vertex));
        }

        // Link the shaders into a program.
        var program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);

        if (getProgramParameter(program, GL_LINK_STATUS) == 0)
        {
            throw new OGL3ShaderLinkingException(_resource.id, getProgramInfoLog(program));
        }

        // Delete the shaders now that they're linked
        glDeleteShader(vertex);
        glDeleteShader(fragment);

        // Fetch the location of all the shaders texture and interface blocks, also bind blocks to a binding point.
        var textureLocations = [ for (t in _resource.layout.textures) glGetUniformLocation(program, t) ];
        var blockLocations   = [ for (b in _resource.layout.blocks) glGetUniformBlockIndex(program, b.name) ];
        var blockBindings    = [ for (i in 0..._resource.layout.blocks.length) _resource.layout.blocks[i].binding ];

        for (i in 0..._resource.layout.blocks.length)
        {
            glUniformBlockBinding(program, blockLocations[i], blockBindings[i]);
        }

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderLocations(_resource.layout, textureLocations, blockBindings));
    }

    function removeShader(_resource : ShaderResource)
    {
        glDeleteProgram(shaderPrograms[_resource.id]);

        shaderPrograms.remove(_resource.id);
        shaderUniforms.remove(_resource.id);
    }

    function createTexture(_resource : ImageResource)
    {
        var id = [ 0 ];
        glGenTextures(1, id);
        glBindTexture(GL_TEXTURE_2D, id[0]);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _resource.width, _resource.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, _resource.pixels.getData());

        glBindTexture(GL_TEXTURE_2D, 0);

        textureObjects[_resource.id] = id[0];
        samplerObjects[_resource.id] = new Map();
    }

    function removeTexture(_resource : ImageResource)
    {
        glDeleteTextures(1, [ textureObjects[_resource.id] ]);

        for (_ => sampler in samplerObjects[_resource.id])
        {
            glDeleteSamplers(1, [ sampler ]);
        }

        if (framebufferObjects.exists(_resource.id))
        {
            glDeleteFramebuffers(1, [ framebufferObjects[_resource.id] ]);
        }

        textureObjects.remove(_resource.id);
        samplerObjects.remove(_resource.id);
        framebufferObjects.remove(_resource.id);
    }

    //  #endregion

    // #region Command Submission

    /**
     * Iterate over all queued commands and upload their vertex data.
     * 
     * We use `glBufferSubData` to avoid poor performance with mapping buffer ranges.
     * Best range mapping performance is to invalidate the requested range, but if you then write that entire range you kill your performance.
     * To save having to iterate over all objects to count byte size, then iterate again to copy, we just copy and add up size as we go along and then use `glBufferSubData` instead.
     */
    function uploadGeometryData()
    {
        final vtxDst = vertexBuffer.address(0);
        final idxDst = indexBuffer.address(0);

        var vtxUploaded = 0;
        var idxUploaded = 0;

        for (command in commandQueue)
        {
            for (geometry in command.geometry)
            {
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
            }
        }

        if (vtxUploaded > 0)
        {
            glBufferSubData(GL_ARRAY_BUFFER, 0, vtxUploaded, vertexBuffer);
        }
        if (idxUploaded > 0)
        {
            glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, idxUploaded, indexBuffer);
        }
    }

    /**
     * Update the projection, model, and view matrix for each queued command.
     * Unfortunately there's no way to re-use the same projection and view matrix and all three must be copied per command.
     * The most common UBO alignment value is also 256, meaning there's a very good chance 64 bytes (enough for another matrix) will be wasted per command.
     */
    function uploadMatrixData()
    {
        glBindBuffer(GL_UNIFORM_BUFFER, glMatrixBuffer);

        final matDst = matrixBuffer.address(0);

        var bytesUploaded = 0;

        for (command in commandQueue)
        {
            final view       = command.camera.view;
            final projection = command.camera.projection;

            for (geometry in command.geometry)
            {
                final model = geometry.transformation.world.matrix;

                memcpy(matDst.add(bytesUploaded)      , (projection : Float32BufferData).bytes.getData().address((projection : Float32BufferData).byteOffset), 64);
                memcpy(matDst.add(bytesUploaded +  64), (view       : Float32BufferData).bytes.getData().address((view       : Float32BufferData).byteOffset), 64);
                memcpy(matDst.add(bytesUploaded + 128), (model      : Float32BufferData).bytes.getData().address((model      : Float32BufferData).byteOffset), 64);

                bytesUploaded += matrixRangeSize;
            }
        }

        glBufferSubData(GL_UNIFORM_BUFFER, 0, bytesUploaded, matrixBuffer);
    }

    /**
     * Iterate over all uniform blobs provided by the command and update its UBO.
     * Uniform blobs and their blocks are matched by their name.
     * An exception will be thrown if it cannot find a matching block.
     */
    function uploadUniformData()
    {
        glBindBuffer(GL_UNIFORM_BUFFER, glUniformBuffer);

        final dst = uniformBuffer.address(0);

        var byteIndex  = 0;

        for (command in commandQueue)
        {
            for (block in command.uniforms)
            {
                memcpy(
                    dst.add(byteIndex),
                    block.buffer.bytes.getData().address(block.buffer.byteOffset),
                    block.buffer.byteLength);

                byteIndex = Maths.nextMultipleOff(byteIndex + block.buffer.byteLength, glUboAlignment);
            }
        }

        glBufferSubData(GL_UNIFORM_BUFFER, 0, byteIndex, uniformBuffer);
    }

    /**
     * Loop over all commands and issue draw calls for them.
     */
    function drawCommands()
    {
        var matOffset = 0;
        var idxOffset = 0;
        var vtxOffset = 0;
        var unfOffset = 0;

        // Draw the queued commands
        for (command in commandQueue)
        {
            // Change the state so the vertices are drawn correctly.
            updateState(command);

            // Bind the correct range for all uniforms
            for (block in command.uniforms)
            {
                glBindBufferRange(
                    GL_UNIFORM_BUFFER,
                    findBlockIndexByName(block.name, command.shader.layout.blocks),
                    glUniformBuffer,
                    unfOffset,
                    block.buffer.byteLength);
    
                unfOffset = Maths.nextMultipleOff(unfOffset + block.buffer.byteLength, glUboAlignment);
            }

            for (geometry in command.geometry)
            {
                // Bind the correct range for the matrix buffer
                glBindBufferRange(
                    GL_UNIFORM_BUFFER,
                    findBlockIndexByName("flurry_matrices", command.shader.layout.blocks),
                    glMatrixBuffer,
                    matOffset,
                    192);

                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})',
                            command.primitive.getPrimitiveType(),
                            _indices.shortAccess.length,
                            GL_UNSIGNED_SHORT,
                            idxOffset,
                            vtxOffset);

                        idxOffset += _indices.buffer.byteLength;
                        vtxOffset += Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);
                    case UnIndexed(_vertices):
                        final numOfVerts = Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);
                        final primitive  = command.primitive.getPrimitiveType();

                        glDrawArrays(primitive, vtxOffset, numOfVerts);

                        vtxOffset += numOfVerts;
                }

                matOffset += matrixRangeSize;
            }
        }
    }

    // #endregion

    // #region State Management

    /**
     * Setup the required openGL state to draw a command.
     * The current state is stored in this class, to reduce expensive state changes we check to see
     * if the provided command has a different set to whats currently set.
     * @param _command Command to set the state for.
     */
    function updateState(_command : DrawCommand)
    {
        updateFramebuffer(_command.target);
        updateShader(_command.shader);
        updateTextures(_command.shader.layout.textures.length, _command.textures, _command.samplers);
        updateDepth(_command.depth);
        updateStencil(_command.stencil);
        updateBlending(_command.blending);

        // If the camera does not specify a viewport (non orthographic) then the full size of the target is used.
        switch _command.camera.viewport
        {
            case None:
                switch target
                {
                    case Backbuffer:
                        updateViewport(0, 0, backbuffer.width, backbuffer.height);
                    case Texture(_image):
                        updateViewport(0, 0, _image.width, _image.height);
                }
            case Viewport(_x, _y, _width, _height):
                updateViewport(_x, _y, _width, _height);
        }

        // If the camera does not specify a clip rectangle then the full size of the target is used.
        switch _command.clip
        {
            case None:
                switch target
                {
                    case Backbuffer:
                        updateClip(0, 0, backbuffer.width, backbuffer.height);
                    case Texture(_image):
                        updateClip(0, 0, _image.width, _image.height);
                }
            case Clip(_x, _y, _width, _height):
                updateClip(_x, _y, _width, _height);
        }
    }

    /**
     * Enables and binds all textures and samplers for drawing a command.
     * The currently bound textures are tracked to stop re-binding the same textures.
     * @param _command Command to bind textures and samplers for.
     */
    function updateTextures(_expectedTextures : Int, _textures : ReadOnlyArray<ImageFrameResource>, _samplers : ReadOnlyArray<SamplerState>)
    {
        // If the shader description specifies more textures than the command provides throw an exception.
        // If less is specified than provided we just ignore the extra, maybe we should throw as well?
        if (_expectedTextures >= _textures.length)
        {
            // then go through each texture and bind it if it isn't already.
            for (i in 0..._textures.length)
            {
                // Bind and activate the texture if its not already bound.
                final glTextureID = textureObjects.get(_textures[i].image);

                if (glTextureID != textureSlots[i])
                {
                    glActiveTexture(GL_TEXTURE0 + i);
                    glBindTexture(GL_TEXTURE_2D, glTextureID);

                    textureSlots[i] = glTextureID;
                }

                // Fetch the custom sampler (first create it if a hash of the sampler is not found).
                var currentSampler = defaultSampler;
                if (i < _samplers.length)
                {
                    final samplerHash     = _samplers[i].hash();
                    final textureSamplers = samplerObjects[_textures[i].id];

                    if (!textureSamplers.exists(samplerHash))
                    {
                        textureSamplers[samplerHash] = createSamplerObject(_samplers[i]);
                    }

                    currentSampler = textureSamplers[samplerHash];
                }

                // If its not already bound bind it and update the bound sampler array.
                if (currentSampler != samplerSlots[i])
                {
                    glBindSampler(i, currentSampler);

                    samplerSlots[i] = currentSampler;
                }
            }
        }
        else
        {
            throw new OGL3NotEnoughTexturesException(_expectedTextures, _textures.length);
        }
    }

    /**
     * Either sets the framebuffer to the backbuffer or to an uploaded texture.
     * If the texture has not yet had a framebuffer generated for it, it is done on demand.
     * This could be something which is done on texture creation in the future.
     * @param _newTarget New target
     */
    function updateFramebuffer(_newTarget : TargetState)
    {
        switch _newTarget
        {
            case Backbuffer:
                switch target
                {
                    case Backbuffer: // no change in target
                    case Texture(_):
                        glBindFramebuffer(GL_FRAMEBUFFER, backbuffer.framebuffer);
                }
            case Texture(_requested):
                switch target
                {
                    case Backbuffer:
                        updateTextureFramebuffer(_requested);
                    case Texture(_current):
                        if (_current.id != _requested.id)
                        {
                            updateTextureFramebuffer(_requested);
                        }
                }
        }

        target = _newTarget;
    }

    function updateShader(_newShader : ShaderResource)
    {
        if (_newShader != shader)
        {
            glUseProgram(shaderPrograms.get(_newShader.id));

            shader = _newShader;
        }
    }

    function updateClip(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        if (clip.x != _x || clip.y != _y || clip.w != _width || clip.h != _width)
        {
            glScissor(_x, _y, _width, _height);

            clip.set(_x, _y, _width, _height);
        }
    }

    function updateViewport(_x : Int, _y : Int, _width : Int, _height : Int)
    {
        if (viewport.x != _x || viewport.y != _y || viewport.w != _width || viewport.h != _height)
        {
            glViewport(_x, _y, _width, _height);

            viewport.set(_x, _y, _width, _height);
        }
    }

    function updateDepth(_newDepth : DepthState)
    {
        if (!_newDepth.equals(depth))
        {
            if (!_newDepth.depthTesting)
            {
                glDisable(GL_DEPTH_TEST);
            }
            else
            {
                if (_newDepth.depthTesting != depth.depthTesting)
                {
                    glEnable(GL_DEPTH_TEST);
                }
                if (_newDepth.depthMasking != depth.depthMasking)
                {
                    glDepthMask(_newDepth.depthMasking);
                }
                if (_newDepth.depthFunction != depth.depthFunction)
                {
                    glDepthFunc(_newDepth.depthFunction.getComparisonFunc());
                }
            }

            depth.copyFrom(_newDepth);
        }
    }

    function updateStencil(_newStencil : StencilState)
    {
        if (!_newStencil.equals(stencil))
        {
            if (!_newStencil.stencilTesting)
            {
                glDisable(GL_STENCIL_TEST);
            }
            else
            {
                if (_newStencil.stencilTesting != stencil.stencilTesting)
                {
                    glEnable(GL_STENCIL_TEST);
                }

                // Front tests
                if (_newStencil.stencilFrontMask != stencil.stencilFrontMask)
                {
                    glStencilMaskSeparate(GL_FRONT, _newStencil.stencilFrontMask);
                }
                if (_newStencil.stencilFrontFunction != stencil.stencilFrontFunction)
                {
                    glStencilFuncSeparate(GL_FRONT, _newStencil.stencilFrontFunction.getComparisonFunc(), 1, 0xff);
                }
                if (_newStencil.stencilFrontTestFail != stencil.stencilFrontTestFail ||
                    _newStencil.stencilFrontDepthTestFail != stencil.stencilFrontDepthTestFail ||
                    _newStencil.stencilFrontDepthTestPass != stencil.stencilFrontDepthTestPass)
                {
                    glStencilOpSeparate(
                        GL_FRONT,
                        _newStencil.stencilFrontTestFail.getStencilFunc(),
                        _newStencil.stencilFrontDepthTestFail.getStencilFunc(),
                        _newStencil.stencilFrontDepthTestPass.getStencilFunc());
                }

                // Back tests
                if (_newStencil.stencilBackMask != stencil.stencilBackMask)
                {
                    glStencilMaskSeparate(GL_BACK, _newStencil.stencilBackMask);
                }
                if (_newStencil.stencilBackFunction != stencil.stencilBackFunction)
                {
                    glStencilFuncSeparate(GL_BACK, _newStencil.stencilBackFunction.getComparisonFunc(), 1, 0xff);
                }
                if (_newStencil.stencilBackTestFail != stencil.stencilBackTestFail ||
                    _newStencil.stencilBackDepthTestFail != stencil.stencilBackDepthTestFail ||
                    _newStencil.stencilBackDepthTestPass != stencil.stencilBackDepthTestPass)
                {
                    glStencilOpSeparate(
                        GL_BACK,
                        _newStencil.stencilBackTestFail.getStencilFunc(),
                        _newStencil.stencilBackDepthTestFail.getStencilFunc(),
                        _newStencil.stencilBackDepthTestPass.getStencilFunc());
                }
            }

            stencil.copyFrom(_newStencil);
        }
    }

    function updateBlending(_newBlend : BlendState)
    {
        if (!_newBlend.equals(blend))
        {
            if (_newBlend.enabled)
            {
                if (!blend.enabled)
                {
                    glEnable(GL_BLEND);
                }

                glBlendFuncSeparate(
                    _newBlend.srcRGB.getBlendMode(),
                    _newBlend.dstRGB.getBlendMode(),
                    _newBlend.srcAlpha.getBlendMode(),
                    _newBlend.dstAlpha.getBlendMode());
            }
            else
            {
                glDisable(GL_BLEND);
            }

            blend.copyFrom(_newBlend);
        }
    }

    /**
     * Bind a framebuffer from the provided image resource.
     * If a framebuffer does not exist for the image, create one and store it.
     * @param _image Image to bind a framebuffer for.
     */
    function updateTextureFramebuffer(_image : ImageResource)
    {
        if (!framebufferObjects.exists(_image.id))
        {
            // Create the framebuffer
            var fbo = [ 0 ];
            glGenFramebuffers(1, fbo);
            glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureObjects.get(_image.id), 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            {
                throw new OGL3IncompleteFramebufferException(_image.id);
            }

            framebufferObjects.set(_image.id, fbo[0]);

            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }

        glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects.get(_image.id));
    }

    /**
     * Creates a new openGL sampler object from a flurry sampler state instance.
     * @param _sampler State to create an openGL sampler from.
     * @return OpenGL sampler object.
     */
    function createSamplerObject(_sampler : SamplerState) : Int
    {
        var samplers = [ 0 ];
        glGenSamplers(1, samplers);
        glSamplerParameteri(samplers[0], GL_TEXTURE_MAG_FILTER, _sampler.minification.getFilterType());
        glSamplerParameteri(samplers[0], GL_TEXTURE_MIN_FILTER, _sampler.magnification.getFilterType());
        glSamplerParameteri(samplers[0], GL_TEXTURE_WRAP_S, _sampler.uClamping.getEdgeClamping());
        glSamplerParameteri(samplers[0], GL_TEXTURE_WRAP_T, _sampler.vClamping.getEdgeClamping());

        return samplers[0];
    }

    // #endregion

    /**
     * Creates a new backbuffer representation.
     * Can optionally remove the existing custom backbuffer.
     * This is an expensive function as it makes two framebuffer binding calls
     * and wipes the state of all bound textures and samplers.
     * @param _width Width of the new backbuffer.
     * @param _height Height of the new backbuffer.
     * @param _remove If the existing backbuffer should be removed.
     * @return BackBuffer instance.
     */
    function createBackbuffer(_width : Int, _height : Int, _remove : Bool = true) : BackBuffer
    {
        // Cleanup previous backbuffer
        if (_remove)
        {
            glDeleteTextures(1, [ backbuffer.texture ]);
            glDeleteRenderbuffers(1, [ backbuffer.depthStencil ]);
            glDeleteFramebuffers(1, [ backbuffer.framebuffer ]);
        }

        var tex = [ 0 ];
        glGenTextures(1, tex);
        glBindTexture(GL_TEXTURE_2D, tex[0]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        untyped __cpp__('glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, {0}, {1}, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr)', _width, _height);

        var rbo = [ 0 ];
        glGenRenderbuffers(1, rbo);
        glBindRenderbuffer(GL_RENDERBUFFER, rbo[0]);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, _width, _height);

        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        glBindTexture(GL_TEXTURE_2D, 0);

        var fbo = [ 0 ];
        glGenFramebuffers(1, fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex[0], 0);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo[0]);

        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            throw new OGL3IncompleteFramebufferException('backbuffer');
        }

        // Cleanup / reset state after setting up new framebuffer.
        switch target
        {
            case Backbuffer:
                glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
            case Texture(_image):
                glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects.get(_image.id));
        }

        for (i in 0...GL_MAX_TEXTURE_IMAGE_UNITS)
        {
            textureSlots[i] = 0;
            samplerSlots[i] = 0;
        }

        return new BackBuffer(_width, _height, 1, tex[0], rbo[0], fbo[0]);
    }

    /**
     * Finds the first shader block with the provided name.
     * If no matching block is found an exception is thrown.
     * @param _name Name to look for.
     * @param _blocks Array of all shader blocks.
     * @return Index into the array of blocks to the first matching block.
     */
    function findBlockIndexByName(_name : String, _blocks : ReadOnlyArray<ShaderBlock>) : Int
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].name == _name)
            {
                return i;
            }
        }

        throw new OGL3UniformBlockNotFoundException(_name);
    }
}

/**
 * Representation of the backbuffer.
 */
private class BackBuffer
{
    public final width : Int;

    public final height : Int;

    public final scale : Float;

    public final texture : Int;

    public final depthStencil : Int;

    public final framebuffer : Int;

    public function new(_width : Int, _height : Int, _scale : Float, _tex : Int, _depthStencil : Int, _fbo : Int)
    {
        width        = _width;
        height       = _height;
        scale        = _scale;
        texture      = _tex;
        depthStencil = _depthStencil;
        framebuffer  = _fbo;
    }
}

/**
 * Stores the location of all a shaders uniforms
 */
private class ShaderLocations
{
    /**
     * Layout of the shader.
     */
    public final layout : ShaderLayout;

    /**
     * Location of all texture uniforms.
     */
    public final textureLocations : Array<Int>;

    /**
     * Binding points of all shader blocks.
     */
    public final blockBindings : Array<Int>;

    public function new(_layout : ShaderLayout, _textureLocations : Array<Int>, _blockBindings : Array<Int>)
    {
        layout           = _layout;
        textureLocations = _textureLocations;
        blockBindings    = _blockBindings;
    }
}

private class OGL3FailedToLoad extends Exception
{
    public function new()
    {
        super('Failed to load OpenGL library');
    }
}

private class OGL3NoShaderSourceException extends Exception
{
    public function new(_id : String)
    {
        super('$_id does not contain source code for a openGL 3.2 shader');
    }
}

private class OGL3VertexCompilationError extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to compile the vertex shader for $_id : $_error');
    }
}

private class OGL3FragmentCompilationError extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to compile the fragment shader for $_id : $_error');
    }
}

private class OGL3ShaderLinkingException extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to link a shader from $_id : $_error');
    }
}

private class OGL3IncompleteFramebufferException extends Exception
{
    public function new(_error : String)
    {
        super(_error);
    }
}

private class OGL3NotEnoughTexturesException extends Exception
{
    public function new(_expected : Int, _actual : Int)
    {
        super('Shader expects $_expected textures but the draw command only provided $_actual');
    }
}

private class OGL3UniformBlockNotFoundException extends Exception
{
    public function new(_blockName)
    {
        super('Unable to find a uniform block with the name $_blockName');
    }
}

private class OGL3CameraViewportNotSetException extends Exception
{
    public function new()
    {
        super('A viewport must be defined for orthographic cameras');
    }
}
