package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader.Ogl3ShaderBlock;
import haxe.ds.Vector;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader.Ogl3Shader;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
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
import hxrx.ISubscription;
import hxrx.observer.Observer;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererOgl3Config;
import uk.aidanlee.flurry.api.gpu.state.TargetState;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.Filtering;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.gpu.textures.EdgeClamping;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.resources.Resource.ResourceID;
import uk.aidanlee.flurry.api.resources.ResourceEvents;

using cpp.NativeArray;

@:nullSafety(Off) class OGL3Backend implements IRendererBackend
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
    final shaderPrograms : Map<ResourceID, Int>;

    /**
     * Shader uniform locations keyed by their associated shader resource IDs.
     */
    final shaderUniforms : Map<ResourceID, ShaderInformation>;

    /**
     * Texture objects keyed by their associated image resource IDs.
     */
    final textureObjects : Map<ResourceID, Int>;

    /**
     * Keep track of all our texture sizes.
     * After they are created draw calls refer to their IDs so we manually store the dimensions.
     * Could use glGet calls but they can be slow.
     */
    final textureInfo : Map<ResourceID, TextureInformation>;

    /**
     * The sampler objects which have been created for each specific texture.
     */
    final samplerObjects : Map<ResourceID, Map<SamplerState, Int>>;

    /**
     * Framebuffer objects keyed by their associated image resource IDs.
     * Framebuffers will only be generated when an image resource is used as a target.
     * Will be destroyed when the associated image resource is destroyed.
     */
    final framebufferObjects : Map<ResourceID, Int>;

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
    var shader     : ResourceID;
    final clip     : Rectangle;
    final viewport : Rectangle;
    var stencil    : StencilState;
    var blend      : BlendState;
    var depth      : DepthState;

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
        textureInfo        = [];
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
        blend        = BlendState.none;
        depth        = DepthState.none;
        stencil      = StencilState.none;
        shader       = 0;
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

        resourceCreatedSubscription = resourceEvents.created.subscribe(new Observer(onResourceCreated, null, null));
        resourceRemovedSubscription = resourceEvents.removed.subscribe(new Observer(onResourceRemoved, null, null));

        displaySizeChangedSubscription   = displayEvents.sizeChanged.subscribe(new Observer(onSizeChanged, null, null));
        displayChangeRequestSubscription = displayEvents.changeRequested.subscribe(new Observer(onChangeRequest, null, null));

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
        textureInfo.clear();
        textureObjects.clear();
        samplerObjects.clear();
        framebufferObjects.clear();

        SDL.GL_DeleteContext(glContext);
        SDL.destroyWindow(window);
    }

    public function uploadTexture(_frame : PageFrameResource, _data : BytesData)
    {
        final currentImage = textureSlots[0];
        final toUpdateId   = textureObjects.get(_frame.page);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, toUpdateId);

        glTexSubImage2D(GL_TEXTURE_2D, 0, _frame.x, _frame.y, _frame.width, _frame.height, GL_RGBA, GL_UNSIGNED_BYTE, _data);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, currentImage);
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
        if (_resource is PageResource)
        {
            createTexture(cast _resource);
        }
        else if (_resource is Ogl3Shader)
        {
            createShader(cast _resource);
        }
    }

    function onResourceRemoved(_resource : Resource)
    {
        if (_resource is PageResource)
        {
            removeTexture(_resource.id);
        }
        else if (_resource is Ogl3Shader)
        {
            removeShader(_resource.id);
        }
    }

    function createShader(_resource : Ogl3Shader)
    {
        if (shaderPrograms.exists(_resource.id))
        {
            return;
        }

        // Create vertex shader.
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        shaderSource(vertex, _resource.vertCode.toString());
        glCompileShader(vertex);

        if (getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw new OGL3VertexCompilationError(_resource.name, getShaderInfoLog(vertex));
        }

        // Create fragment shader.
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        shaderSource(fragment, _resource.fragCode.toString());
        glCompileShader(fragment);

        if (getShaderParameter(fragment, GL_COMPILE_STATUS) == 0)
        {
            throw new OGL3FragmentCompilationError(_resource.name, getShaderInfoLog(fragment));
        }

        // Link the shaders into a program.
        var program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);

        if (getProgramParameter(program, GL_LINK_STATUS) == 0)
        {
            throw new OGL3ShaderLinkingException(_resource.name, getProgramInfoLog(program));
        }

        // Delete the shaders now that they're linked
        glDeleteShader(vertex);
        glDeleteShader(fragment);

        // Fetch the location of all the shaders texture and interface blocks, also bind blocks to a binding point.

        final textureLocations = new Vector(_resource.samplers.length);
        for (i in 0..._resource.samplers.length)
        {
            textureLocations[i] = glGetUniformLocation(program, _resource.samplers[i]);
        }

        for (block in _resource.blocks)
        {
            final location = glGetUniformBlockIndex(program, block.name);

            glUniformBlockBinding(program, location, block.binding);
        }

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderInformation(_resource.blocks, textureLocations));
    }

    function removeShader(_id : ResourceID)
    {
        glDeleteProgram(shaderPrograms[_id]);

        shaderPrograms.remove(_id);
        shaderUniforms.remove(_id);
    }

    function createTexture(_resource : PageResource)
    {
        var id = [ 0 ];
        glGenTextures(1, id);
        glBindTexture(GL_TEXTURE_2D, id[0]);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _resource.width, _resource.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _resource.pixels.getData());

        glBindTexture(GL_TEXTURE_2D, 0);

        textureInfo[_resource.id] = new TextureInformation(_resource.width, _resource.height);
        textureObjects[_resource.id] = id[0];
        samplerObjects[_resource.id] = new Map();
    }

    function removeTexture(_id : ResourceID)
    {
        glDeleteTextures(1, [ textureObjects[_id] ]);

        for (_ => sampler in samplerObjects[_id])
        {
            glDeleteSamplers(1, [ sampler ]);
        }

        if (framebufferObjects.exists(_id))
        {
            glDeleteFramebuffers(1, [ framebufferObjects[_id] ]);
        }

        textureInfo.remove(_id);
        textureObjects.remove(_id);
        samplerObjects.remove(_id);
        framebufferObjects.remove(_id);
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
                final info = shaderUniforms[command.shader];
                final idx  = findBlockIndexByName(block.name, info.blocks);

                if (idx != -1)
                {
                    glBindBufferRange(GL_UNIFORM_BUFFER, idx, glUniformBuffer, unfOffset, block.buffer.byteLength);
                }
    
                unfOffset = Maths.nextMultipleOff(unfOffset + block.buffer.byteLength, glUboAlignment);
            }

            for (geometry in command.geometry)
            {
                // Bind the correct range for the matrix buffer
                final info = shaderUniforms[command.shader];
                final idx  = findBlockIndexByName("flurry_matrices", info.blocks);

                if (idx != -1)
                {
                    glBindBufferRange(GL_UNIFORM_BUFFER, idx, glMatrixBuffer, matOffset, 192);
                }

                switch geometry.data
                {
                    case Indexed(_vertices, _indices):
                        // This length needs to be stored in a variable as the next chunk of code is untyped.
                        // putting this directly into the parameter will generate invalid cpp!
                        final length = _indices.shortAccess.length;

                        untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})',
                            getPrimitiveType(command.primitive),
                            length,
                            GL_UNSIGNED_SHORT,
                            idxOffset,
                            vtxOffset);

                        idxOffset += _indices.buffer.byteLength;
                        vtxOffset += Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);
                    case UnIndexed(_vertices):
                        final numOfVerts = Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);
                        final primitive  = getPrimitiveType(command.primitive);

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
        updateTextures(_command.shader, _command.textures, _command.samplers);
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
                    case Texture(_id):
                        final size = textureInfo[_id];
                        updateViewport(0, 0, size.width, size.height);
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
                    case Texture(_id):
                        final size = textureInfo[_id];
                        updateClip(0, 0, size.width, size.height);
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
    function updateTextures(_shader : ResourceID, _textures : ReadOnlyArray<ResourceID>, _samplers : ReadOnlyArray<SamplerState>)
    {
        // If the shader description specifies more textures than the command provides throw an exception.
        // If less is specified than provided we just ignore the extra, maybe we should throw as well?
        final info  = shaderUniforms[_shader];
        final count = info.textureLocations.length;

        if (_textures.length >= count)
        {
            // then go through each texture and bind it if it isn't already.
            for (i in 0...count)
            {
                // Bind and activate the texture if its not already bound.
                final glTextureID = textureObjects[_textures[i]];
                final textureUnit = info.textureLocations[i];

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
                    final textureSamplers = samplerObjects[_textures[i]];

                    if (!textureSamplers.exists(_samplers[i]))
                    {
                        textureSamplers[_samplers[i]] = createSamplerObject(_samplers[i]);
                    }

                    currentSampler = textureSamplers[_samplers[i]];
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
            throw new OGL3NotEnoughTexturesException(count, _textures.length);
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
                        if (_current != _requested)
                        {
                            updateTextureFramebuffer(_requested);
                        }
                }
        }

        target = _newTarget;
    }

    function updateShader(_newShader : ResourceID)
    {
        if (_newShader != shader)
        {
            glUseProgram(shaderPrograms[_newShader]);

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
        if (_newDepth != depth)
        {
            if (!_newDepth.enabled)
            {
                glDisable(GL_DEPTH_TEST);
            }
            else
            {
                if (_newDepth.enabled != depth.enabled)
                {
                    glEnable(GL_DEPTH_TEST);
                }
                if (_newDepth.masking != depth.masking)
                {
                    glDepthMask(_newDepth.masking);
                }
                if (_newDepth.func != depth.func)
                {
                    glDepthFunc(getComparisonFunc(_newDepth.func));
                }
            }

            depth = _newDepth;
        }
    }

    function updateStencil(_newStencil : StencilState)
    {
        if (_newStencil != stencil)
        {
            if (!_newStencil.enabled)
            {
                glDisable(GL_STENCIL_TEST);
            }
            else
            {
                if (_newStencil.enabled != stencil.enabled)
                {
                    glEnable(GL_STENCIL_TEST);
                }

                // Front tests
                if (_newStencil.frontFunc != stencil.frontFunc)
                {
                    glStencilFuncSeparate(GL_FRONT, getComparisonFunc(_newStencil.frontFunc), 1, 0xff);
                }
                if (_newStencil.frontTestFail != stencil.frontTestFail ||
                    _newStencil.frontDepthTestFail != stencil.frontDepthTestFail ||
                    _newStencil.frontDepthTestPass != stencil.frontDepthTestPass)
                {
                    glStencilOpSeparate(
                        GL_FRONT,
                        getStencilFunc(_newStencil.frontTestFail),
                        getStencilFunc(_newStencil.frontDepthTestFail),
                        getStencilFunc(_newStencil.frontDepthTestPass));
                }

                // Back tests
                if (_newStencil.backFunc != stencil.backFunc)
                {
                    glStencilFuncSeparate(GL_BACK, getComparisonFunc(_newStencil.backFunc), 1, 0xff);
                }
                if (_newStencil.backTestFail != stencil.backTestFail ||
                    _newStencil.backDepthTestFail != stencil.backDepthTestFail ||
                    _newStencil.backDepthTestPass != stencil.backDepthTestPass)
                {
                    glStencilOpSeparate(
                        GL_BACK,
                        getStencilFunc(_newStencil.backTestFail),
                        getStencilFunc(_newStencil.backDepthTestFail),
                        getStencilFunc(_newStencil.backDepthTestPass));
                }
            }

            stencil = _newStencil;
        }
    }

    function updateBlending(_newBlend : BlendState)
    {
        if (_newBlend != blend)
        {
            if (_newBlend.enabled)
            {
                if (!blend.enabled)
                {
                    glEnable(GL_BLEND);
                }

                glBlendFuncSeparate(
                    getBlendMode(_newBlend.srcRgb),
                    getBlendMode(_newBlend.dstRgb),
                    getBlendMode(_newBlend.srcAlpha),
                    getBlendMode(_newBlend.dstAlpha));
            }
            else
            {
                glDisable(GL_BLEND);
            }

            blend = _newBlend;
        }
    }

    /**
     * Bind a framebuffer from the provided image resource.
     * If a framebuffer does not exist for the image, create one and store it.
     * @param _image Image to bind a framebuffer for.
     */
    function updateTextureFramebuffer(_image : ResourceID)
    {
        if (!framebufferObjects.exists(_image))
        {
            // Create the framebuffer
            var fbo = [ 0 ];
            glGenFramebuffers(1, fbo);
            glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureObjects[_image], 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            {
                throw new OGL3IncompleteFramebufferException(Std.string(_image));
            }

            framebufferObjects.set(_image, fbo[0]);

            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }

        glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects[_image]);
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
        glSamplerParameteri(samplers[0], GL_TEXTURE_MAG_FILTER, getFilterType(_sampler.minification));
        glSamplerParameteri(samplers[0], GL_TEXTURE_MIN_FILTER, getFilterType(_sampler.magnification));
        glSamplerParameteri(samplers[0], GL_TEXTURE_WRAP_S, getEdgeClamping(_sampler.uClamping));
        glSamplerParameteri(samplers[0], GL_TEXTURE_WRAP_T, getEdgeClamping(_sampler.vClamping));

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
                glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects[_image]);
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
    function findBlockIndexByName(_name : String, _blocks : Vector<Ogl3ShaderBlock>) : Int
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].name == _name)
            {
                return i;
            }
        }

        return -1;
    }

    function getPrimitiveType(_primitive : PrimitiveType)
    {
        return switch _primitive
        {
            case Points        : GL_POINTS;
            case Lines         : GL_LINES;
            case LineStrip     : GL_LINE_STRIP;
            case Triangles     : GL_TRIANGLES;
            case TriangleStrip : GL_TRIANGLE_STRIP;
        }
    }

    function getBlendMode(_mode : BlendMode)
    {
        return switch _mode
        {
            case Zero             : GL_ZERO;
            case One              : GL_ONE;
            case SrcAlphaSaturate : GL_SRC_ALPHA_SATURATE;
            case SrcColor         : GL_SRC_COLOR;
            case OneMinusSrcColor : GL_ONE_MINUS_SRC_COLOR;
            case SrcAlpha         : GL_SRC_ALPHA;
            case OneMinusSrcAlpha : GL_ONE_MINUS_SRC_ALPHA;
            case DstAlpha         : GL_DST_ALPHA;
            case OneMinusDstAlpha : GL_ONE_MINUS_DST_ALPHA;
            case DstColor         : GL_DST_COLOR;
            case OneMinusDstColor : GL_ONE_MINUS_DST_COLOR;
            case _: 0;
        }
    }

    function getComparisonFunc(_func : ComparisonFunction)
    {
        return switch _func
        {
            case Always             : GL_ALWAYS;
            case Never              : GL_NEVER;
            case LessThan           : GL_LESS;
            case Equal              : GL_EQUAL;
            case LessThanOrEqual    : GL_LEQUAL;
            case GreaterThan        : GL_GREATER;
            case GreaterThanOrEqual : GL_GEQUAL;
            case NotEqual           : GL_NOTEQUAL;
        }
    }

    function getStencilFunc(_func : StencilFunction)
    {
        return switch _func
        {
            case Keep          : GL_KEEP;
            case Zero          : GL_ZERO;
            case Replace       : GL_REPLACE;
            case Invert        : GL_INVERT;
            case Increment     : GL_INCR;
            case IncrementWrap : GL_INCR_WRAP;
            case Decrement     : GL_DECR;
            case DecrementWrap : GL_DECR_WRAP;
        }
    }

    function getFilterType(_filter : Filtering)
    {
        return switch _filter
        {
            case Nearest : GL_NEAREST;
            case Linear  : GL_LINEAR;
        }
    }

    function getEdgeClamping(_clamping : EdgeClamping)
    {
        return switch _clamping
        {
            case Wrap   : GL_REPEAT;
            case Mirror : GL_MIRRORED_REPEAT;
            case Clamp  : GL_CLAMP_TO_EDGE;
            case Border : GL_CLAMP_TO_BORDER;
        }
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
private class ShaderInformation
{
    /**
     * All unique UBOs in this shader.
     */
    public final blocks : Vector<Ogl3ShaderBlock>;

    /**
     * Location of all texture uniforms.
     */
    public final textureLocations : Vector<Int>;

    public function new(_blocks, _textureLocations)
    {
        blocks           = _blocks;
        textureLocations = _textureLocations;
    }
}

private class TextureInformation
{
    public final width : Int;

    public final height : Int;

    public function new(_width, _height)
    {
        width  = _width;
        height = _height;
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
