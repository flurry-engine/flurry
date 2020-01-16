package uk.aidanlee.flurry.api.gpu.backend;

import haxe.io.Bytes;
import haxe.ds.Map;
import cpp.Stdlib;
import cpp.Float32;
import cpp.Int32;
import cpp.UInt8;
import cpp.Pointer;
import sdl.GLContext;
import sdl.Window;
import sdl.SDL;
import opengl.GL.*;
import opengl.WebGL;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderBlock;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.camera.Camera3D;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.utils.opengl.GLSyncWrapper;

using Safety;
using cpp.NativeArray;
using uk.aidanlee.flurry.utils.opengl.GLConverters;

class OGL4Backend implements IRendererBackend
{
    /**
     * The number of floats in each vertex.
     */
    static final VERTEX_FLOAT_SIZE = 9;

    /**
     * The byte offset for the position in each vertex.
     */
    static final VERTEX_OFFSET_POS = 0;

    /**
     * The byte offset for the colour in each vertex.
     */
    static final VERTEX_OFFSET_COL = 3;

    /**
     * The byte offset for the texture coordinates in each vertex.
     */
    static final VERTEX_OFFSET_TEX = 7;

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
    final glVbo : Int;

    /**
     * The single Index buffer used by the backend.
     */
    final glIbo : Int;

    /**
     * The single VAO which is bound once when the backend is created.
     */
    final glVao : Int;

    /**
     * Constant vector instance which is used to transform vertices when copying into the vertex buffer.
     */
    final transformationVector : Vector3;

    /**
     * Constant identity matrix, used as the model matrix for non multi draw shaders.
     */
    final identityMatrix : Matrix;

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
     * The default sampler object to use if none is specified.
     */
    final defaultSampler : Int;

    /**
     * OpenGL sync objects used to lock writing into buffer ranges until they are visible to the GPU.
     */
    final rangeSyncPrimitives : Array<GLSyncWrapper>;

    /**
     * Constant vector which will be used to flip perspective cameras on their y axis.
     */
    final perspectiveYFlipVector : Vector3;

    /**
     * Colour RGBA normalised float array used to clear the display
     */
    final clearColour : Array<cpp.Float32>;

    /**
     * Array of opengl textures objects which will be bound.
     * Size of this array is equal to the max number of texture bindings allowed .
     */
    final textureSlots : Array<Int>;

    /**
     * Index pointing to the current writable vertex buffer range.
     */
    var vertexBufferRangeIndex : Int;

    /**
     * Index pointing to the current writing index buffer range.
     */
    var indexBufferRangeIndex : Int;

    /**
     * The index into the vertex buffer to write.
     * Writing more floats must increment this value. Set the to current ranges offset in preDraw.
     */
    var vertexFloatOffset : Int;

    /**
     * Offset to use when calling openngl draw commands.
     * Writing more verticies must increment this value. Set the to current ranges offset in preDraw.
     */
    var vertexOffset : Int;

    /**
     * The current index position into the index buffer we are writing to.
     * Like vertexOffset at the beginning of each frame it is set to an initial offset into the index buffer.
     */
    var indexOffset : Int;

    /**
     * The number of bytes into the index buffer we are writing to.
     */
    var indexByteOffset : Int;

    /**
     * Backbuffer display, default target if none is specified.
     */
    var backbuffer : BackBuffer;

    /**
     * The index of the current buffer range which is being written into this frame.
     */
    var currentRange : Int;

    // GL state variables

    /**
     * The current viewport size.
     */
    var viewport : Rectangle;

    /**
     * The current scissor region size.
     */
    var clip : Rectangle;

    /**
     * The target to use. If null the backbuffer is used.
     */
    var target : ImageResource;

    /**
     * Shader to use.
     */
    var shader : ShaderResource;

    /**
     * The bound ssbo buffer.
     */
    var ssbo : Int;

    /**
     * The bound indirect command buffer.
     */
    var cmds : Int;

    // SDL Window and GL Context

    var window : Window;

    var glContext : GLContext;

    /**
     * Creates a new openGL 4.5 renderer.
     * @param _renderer           Access to the renderer which owns this backend.
     * @param _dynamicVertices    The maximum number of dynamic vertices in the buffer.
     * @param _unchangingVertices The maximum number of static vertices in the buffer.
     */
    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        createWindow(_windowConfig);

        resourceEvents = _resourceEvents;
        displayEvents  = _displayEvents;

        var staticVertexBuffer = _rendererConfig.unchangingVertices;
        var streamVertexBuffer = _rendererConfig.dynamicVertices;
        var staticIndexBuffer  = _rendererConfig.unchangingIndices;
        var streamIndexBuffer  = _rendererConfig.dynamicIndices;

        // Create two empty buffers, for the vertex and index data
        var buffers = [ 0, 0 ];
        glCreateBuffers(2, buffers);

        untyped __cpp__("glNamedBufferStorage({0}, {1}, nullptr, {2})", buffers[0], staticVertexBuffer * 9 * 4 + ((streamVertexBuffer * 9 * 4) * 3), GL_DYNAMIC_STORAGE_BIT | GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
        untyped __cpp__("glNamedBufferStorage({0}, {1}, nullptr, {2})", buffers[1], staticIndexBuffer * 2  + ((streamIndexBuffer * 2) * 3), GL_DYNAMIC_STORAGE_BIT | GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);

        // Create the vao and bind the vbo to it.
        var vao = [ 0 ];
        glCreateVertexArrays(1, vao);
        glVertexArrayVertexBuffer(vao[0], 0, buffers[0], 0, Float32BufferData.BYTES_PER_FLOAT * VERTEX_FLOAT_SIZE);

        // Enable and setup the vertex attributes for this batcher.
        glEnableVertexArrayAttrib(vao[0], 0);
        glEnableVertexArrayAttrib(vao[0], 1);
        glEnableVertexArrayAttrib(vao[0], 2);

        glVertexArrayAttribFormat(buffers[0], 0, 3, GL_FLOAT, false, Float32BufferData.BYTES_PER_FLOAT * VERTEX_OFFSET_POS);
        glVertexArrayAttribFormat(buffers[0], 1, 4, GL_FLOAT, false, Float32BufferData.BYTES_PER_FLOAT * VERTEX_OFFSET_COL);
        glVertexArrayAttribFormat(buffers[0], 2, 2, GL_FLOAT, false, Float32BufferData.BYTES_PER_FLOAT * VERTEX_OFFSET_TEX);

        glVertexArrayAttribBinding(vao[0], 0, 0);
        glVertexArrayAttribBinding(vao[0], 1, 0);
        glVertexArrayAttribBinding(vao[0], 2, 0);

        glVbo = buffers[0];
        glIbo = buffers[1];
        glVao = vao[0];

        // Bind our VAO once.
        glBindVertexArray(glVao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIbo);

        var samplers = [ 0 ];
        glGenSamplers(1, samplers);
        defaultSampler = samplers[0];
        glSamplerParameteri(defaultSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // Map the streaming parts of the vertex and index buffer.
        var vtxBuffer : Pointer<UInt8> = Pointer.fromRaw(glMapNamedBufferRange(glVbo, staticVertexBuffer * 9 * 4, (streamVertexBuffer * 9 * 4) * 3, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT)).reinterpret();
        var idxBuffer : Pointer<UInt8> = Pointer.fromRaw(glMapNamedBufferRange(glIbo, staticIndexBuffer * 2     , (streamIndexBuffer * 2) * 3     , GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT)).reinterpret();

        perspectiveYFlipVector = new Vector3(31, -1, 1);
        transformationVector   = new Vector3();
        identityMatrix         = new Matrix();
        rangeSyncPrimitives    = [ for (i in 0...3) new GLSyncWrapper() ];
        currentRange           = 0;

        backbuffer = createBackbuffer(_windowConfig.width, _windowConfig.height, false);

        // Default blend mode
        // TODO : Move this to be a settable property in the geometry or renderer or something
        glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);

        // Set the clear colour
        clearColour = [ _rendererConfig.clearColour.r, _rendererConfig.clearColour.g, _rendererConfig.clearColour.b, _rendererConfig.clearColour.a ];

        // Default scissor test
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        glClipControl(GL_LOWER_LEFT, GL_ZERO_TO_ONE);

        // default state
        viewport = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        clip     = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        target   = null;
        shader   = null;
        ssbo     = 0;
        cmds     = 0;

        textureSlots       = [ for (_ in 0...GL_MAX_TEXTURE_IMAGE_UNITS) 0 ];
        shaderPrograms     = [];
        shaderUniforms     = [];
        textureObjects     = [];
        samplerObjects     = [];
        framebufferObjects = [];

        resourceEvents.created.add(onResourceCreated);
        resourceEvents.removed.add(onResourceRemoved);
        displayEvents.sizeChanged.add(onSizeChanged);
        displayEvents.changeRequested.add(onChangeRequest);
    }

    /**
     * Unlock the range we will be writing into and set the offsets to that of the range.
     */
    public function preDraw()
    {
        if (rangeSyncPrimitives[currentRange].sync != null)
        {
            while (true)
            {
                var waitReturn = glClientWaitSync(rangeSyncPrimitives[currentRange].sync, GL_SYNC_FLUSH_COMMANDS_BIT, 1000);
                if (waitReturn == GL_ALREADY_SIGNALED || waitReturn == GL_CONDITION_SATISFIED)
                {
                    break;
                }
            }
        }

        // streamStorage.unlockBuffers(currentRange);

        clip.set(0, 0, backbuffer.width, backbuffer.height);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glClearNamedFramebufferfv(backbuffer.framebuffer, GL_COLOR, 0, clearColour);
    }

    /**
     * Upload a series of geometry commands into the current buffer range.
     * @param _commands Commands to upload.
     */
    public function queue(_command : GeometryDrawCommand)
    {
        // for (command in _commands)
        // {
        //     switch (command.uploadType)
        //     {
        //         case Static : staticStorage.uploadGeometry(command);
        //         case Stream, Immediate : streamStorage.uploadGeometry(command);
        //     }
        // }
    }

    /**
     * Submit a series of uploaded commands to be drawn.
     * @param _commands    Commands to draw.
     * @param _recordStats If stats are to be recorded.
     */
    public function submit()
    {
        // for (command in _commands)
        // {
        //     setState(command, _recordStats);

        //     switch (command.uploadType)
        //     {
        //         case Static : staticStorage.draw(command);
        //         case Stream, Immediate : streamStorage.draw(command);
        //     }
        // }
    }

    /**
     * Locks the range we are currenly writing to and increments the index.
     */
    public function postDraw()
    {
        if (rangeSyncPrimitives[currentRange].sync != null)
        {
            glDeleteSync(rangeSyncPrimitives[currentRange].sync);
        }

        rangeSyncPrimitives[currentRange].sync = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

        currentRange = (currentRange + 1) % 3;

        glBlitNamedFramebuffer(
            backbuffer.framebuffer, 0,
            0, 0, backbuffer.width, backbuffer.height,
            0, backbuffer.height, backbuffer.width, 0,
            GL_COLOR_BUFFER_BIT, GL_NEAREST);

        SDL.GL_SwapWindow(window);
    }

    /**
     * Unmap the buffer and iterate over all resources deleting their resources and remove them from the structure.
     */
    public function cleanup()
    {
        resourceEvents.created.remove(onResourceCreated);
        resourceEvents.removed.remove(onResourceRemoved);
        displayEvents.sizeChanged.remove(onSizeChanged);
        displayEvents.changeRequested.remove(onChangeRequest);

        glUnmapNamedBuffer(glVbo);

        for (shaderID in shaderPrograms.keys())
        {
            glDeleteProgram(shaderPrograms.get(shaderID));

            shaderPrograms.remove(shaderID);
            shaderUniforms.remove(shaderID);
        }

        for (textureID in textureObjects.keys())
        {
            glDeleteTextures(1, [ textureObjects.get(textureID) ]);
            textureObjects.remove(textureID);

            if (framebufferObjects.exists(textureID))
            {
                glDeleteFramebuffers(1, [ framebufferObjects.get(textureID) ]);
                framebufferObjects.remove(textureID);
            }
        }

        SDL.GL_DeleteContext(glContext);
        SDL.destroyWindow(window);
    }

    // #region SDL Window Management

    function createWindow(_options : FlurryWindowConfig)
    {        
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 6);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        window    = SDL.createWindow(_options.title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
        glContext = SDL.GL_CreateContext(window);

        SDL.GL_MakeCurrent(window, glContext);

        if (glad.Glad.gladLoadGLLoader(untyped __cpp__('&SDL_GL_GetProcAddress')) == 0)
        {
            throw 'failed to load gl library';
        }
    }

    function onChangeRequest(_event : DisplayEventChangeRequest)
    {
        SDL.setWindowSize(window, _event.width, _event.height);
        SDL.setWindowFullscreen(window, _event.fullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
        SDL.GL_SetSwapInterval(_event.vsync ? 1 : 0);
    }

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

    /**
     * Create a shader from a resource.
     * @param _resource Resource to create a shader of.
     */
    function createShader(_resource : ShaderResource)
    {
        if (_resource.ogl4 == null)
        {
            throw 'OpenGL 4.5 Backend Exception : ${_resource.id} : Attempting to create a shader from a resource which has no gl45 shader source';
        }

        if (shaderPrograms.exists(_resource.id))
        {
            throw 'OpenGL 4.5 Backend Exception : ${_resource.id} : Attempting to create a shader which already exists';
        }

        var vertex   = 0;
        var fragment = 0;
        if (_resource.ogl4.compiled)
        {
            vertex   = vertexFromSPIRV(_resource.ogl4.vertex);
            fragment = fragmentFromSPIRV(_resource.ogl4.fragment);
        }
        else
        {
            vertex   = vertexFromSource(_resource.ogl4.vertex.toString());
            fragment = fragmentFromSource(_resource.ogl4.fragment.toString());
        }

        // Link the shaders into a program.
        var program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);

        if (WebGL.getProgramParameter(program, GL_LINK_STATUS) == 0)
        {
            throw 'OpenGL 4.5 Backend Exception : ${_resource.id} : Error linking program : ${WebGL.getProgramInfoLog(program)}';
        }

        // Delete the shaders now that they're linked
        glDeleteShader(vertex);
        glDeleteShader(fragment);

        var textureLocations = [ for (t in _resource.layout.textures) glGetUniformLocation(program, t) ];
        var blockLocations   = [ for (b in _resource.layout.blocks) glGetProgramResourceIndex(program, GL_SHADER_STORAGE_BLOCK, b.name) ];
        var blockBindings    = [ for (i in 0..._resource.layout.blocks.length) _resource.layout.blocks[i].binding ];

        for (i in 0..._resource.layout.blocks.length)
        {
            glShaderStorageBlockBinding(program, blockLocations[i], blockBindings[i]);
        }

        var blockBuffers = [ for (i in 0..._resource.layout.blocks.length) 0 ];
        glCreateBuffers(blockBuffers.length, blockBuffers);
        var blockBytes = [ for (i in 0..._resource.layout.blocks.length) generateUniformBlock(_resource.layout.blocks[i], blockBuffers[i], blockBindings[i]) ];

        glBindBuffersBase(GL_SHADER_STORAGE_BUFFER, blockBindings[0], blockBindings.length, blockBuffers);

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderLocations(_resource.layout, textureLocations, blockBindings, blockBuffers, blockBytes));
    }

    function vertexFromSPIRV(_spirv : Bytes) : Int
    {
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        glShaderBinary(1, [ vertex ], GL_SHADER_BINARY_FORMAT_SPIR_V, _spirv.getData(), _spirv.length);
        glSpecializeShader(vertex, 'main', 0, [ 0 ], [ 0 ]);

        return vertex;
    }

    function fragmentFromSPIRV(_spirv : Bytes) : Int
    {
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderBinary(1, [ fragment ], GL_SHADER_BINARY_FORMAT_SPIR_V, _spirv.getData(), _spirv.length);
        glSpecializeShader(fragment, 'main', 0, [ 0 ], [ 0 ]);

        return fragment;
    }

    function vertexFromSource(_source : String) : Int
    {
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        WebGL.shaderSource(vertex, _source);
        glCompileShader(vertex);

        if (WebGL.getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw 'OpenGL 4.5 Backend Exception : Error compiling vertex shader : ${WebGL.getShaderInfoLog(vertex)}';
        }

        return vertex;
    }

    function fragmentFromSource(_source : String) : Int
    {
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        WebGL.shaderSource(fragment, _source);
        glCompileShader(fragment);

        if (WebGL.getShaderParameter(fragment, GL_COMPILE_STATUS) == 0)
        {
            throw 'OpenGL 4.5 Backend Exception : Error compiling fragment shader : ${WebGL.getShaderInfoLog(fragment)}';
        }

        return fragment;
    }

    /**
     * Free the GPU resources used by a shader program.
     * @param _resource Shader resource to remove.
     */
    function removeShader(_resource : ShaderResource)
    {
        glDeleteProgram(shaderPrograms.get(_resource.id));

        shaderPrograms.remove(_resource.id);
        shaderUniforms.remove(_resource.id);
    }

    /**
     * Create a texture from a resource.
     * @param _resource Image resource to create the texture from.
     */
    function createTexture(_resource : ImageResource)
    {
        var ids = [ 0 ];
        glCreateTextures(GL_TEXTURE_2D, 1, ids);

        glTextureParameteri(ids[0], GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTextureParameteri(ids[0], GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTextureParameteri(ids[0], GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTextureParameteri(ids[0], GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        glTextureStorage2D(ids[0], 1, GL_RGBA8, _resource.width, _resource.height);
        glTextureSubImage2D(ids[0], 0, 0, 0, _resource.width, _resource.height, GL_BGRA, GL_UNSIGNED_BYTE, _resource.pixels.getData());

        textureObjects[_resource.id] = ids[0];
        samplerObjects[_resource.id] = new Map();
    }

    /**
     * Free the GPU resources used by a texture.
     * @param _resource Image resource to remove.
     */
    function removeTexture(_resource : ImageResource)
    {
        var samplers = [];
        for (sampler in samplerObjects[_resource.id])
        {
            samplers.push(sampler);
        }
        glDeleteSamplers(samplers.length, samplers);
        glDeleteTextures(1, [ textureObjects.get(_resource.id) ]);

        textureObjects.remove(_resource.id);
        samplerObjects.remove(_resource.id);
    }

    function generateUniformBlock(_block : ShaderBlock, _buffer : Int, _binding : Int) : Bytes
    {
        var blockSize = 0;
        for (val in _block.values)
        {
            switch val.type
            {
                case Matrix4: blockSize += 64;
                case Vector4: blockSize += 16;
                case Int, Float: blockSize += 4;
            }
        }

        var bytes = Bytes.alloc(blockSize);
        glNamedBufferData(_buffer, bytes.length, bytes.getData(), GL_DYNAMIC_DRAW);
        
        return bytes;
    }

    // #endregion

    // #region State Management

    /**
     * Update the openGL state so it can draw the provided command.
     * @param _command      Command to set the state for.
     * @param _enableStats If stats are to be recorded.
     */
    function setState(_command : DrawCommand)
    {
        // Set the render target.
        // If the target is null then the backbuffer is used.
        // Render targets are created on the fly as and when needed since most textures probably won't be used as targets.
        if (_command.target != target)
        {
            target = _command.target;

            if (target != null && !framebufferObjects.exists(target.id))
            {
                // Create the framebuffer
                var fbo = [ 0 ];
                glCreateFramebuffers(1, fbo);
                glNamedFramebufferTexture(fbo[0], GL_COLOR_ATTACHMENT0, textureObjects.get(target.id), 0);

                if (glCheckNamedFramebufferStatus(fbo[0], GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
                {
                    throw 'OpenGL 4.5 Backend Exception : ${target.id} : Framebuffer not complete';
                }

                framebufferObjects.set(target.id, fbo[0]);
            }

            glBindFramebuffer(GL_FRAMEBUFFER, target != null ? framebufferObjects.get(target.id) : backbuffer.framebuffer);
        }

        // Apply shader changes.
        if (shader != _command.shader)
        {
            shader = _command.shader;
            glUseProgram(shaderPrograms.get(shader.id));
        }

        // Apply depth and stencil settings.
        if (_command.depth.depthTesting)
        {
            glEnable(GL_DEPTH_TEST);
            glDepthMask(_command.depth.depthMasking);
            glDepthFunc(_command.depth.depthFunction.getComparisonFunc());
        }
        else
        {
            glDisable(GL_DEPTH_TEST);
        }

        if (_command.stencil.stencilTesting)
        {
            glEnable(GL_STENCIL_TEST);
            
            glStencilMaskSeparate(GL_FRONT, _command.stencil.stencilFrontMask);
            glStencilFuncSeparate(GL_FRONT, _command.stencil.stencilFrontFunction.getComparisonFunc(), 1, 0xff);
            glStencilOpSeparate(
                GL_FRONT,
                _command.stencil.stencilFrontTestFail.getStencilFunc(),
                _command.stencil.stencilFrontDepthTestFail.getStencilFunc(),
                _command.stencil.stencilFrontDepthTestPass.getStencilFunc());

            glStencilMaskSeparate(GL_BACK, _command.stencil.stencilBackMask);
            glStencilFuncSeparate(GL_BACK, _command.stencil.stencilBackFunction.getComparisonFunc(), 1, 0xff);
            glStencilOpSeparate(
                GL_BACK,
                _command.stencil.stencilBackTestFail.getStencilFunc(),
                _command.stencil.stencilBackDepthTestFail.getStencilFunc(),
                _command.stencil.stencilBackDepthTestPass.getStencilFunc());
        }
        else
        {
            glDisable(GL_STENCIL_TEST);
        }

        // Set the viewport.
        // If the viewport of the command is null then the backbuffer size is used (size of the window).
        var cmdViewport = _command.camera.viewport;
        if (cmdViewport == null)
        {
            if (target == null)
            {
                cmdViewport = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
            }
            else
            {
                cmdViewport = new Rectangle(0, 0, target.width, target.height);
            }
        }

        if (!viewport.equals(cmdViewport))
        {
            viewport.set(cmdViewport.x, cmdViewport.y, cmdViewport.w, cmdViewport.h);

            var x = viewport.x *= target == null ? backbuffer.scale : 1;
            var y = viewport.y *= target == null ? backbuffer.scale : 1;
            var w = viewport.w *= target == null ? backbuffer.scale : 1;
            var h = viewport.h *= target == null ? backbuffer.scale : 1;

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            glViewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
        }

        // Apply the scissor clip.
        var cmdClip = _command.clip;
        if (cmdClip == null)
        {
            if (target == null)
            {
                cmdClip = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
            }
            else
            {
                cmdClip = new Rectangle(0, 0, target.width, target.height);
            }
        }

        if (!clip.equals(cmdClip))
        {
            clip.copyFrom(cmdClip);

            var x = cmdClip.x * (target == null ? backbuffer.scale : 1);
            var y = cmdClip.y * (target == null ? backbuffer.scale : 1);
            var w = cmdClip.w * (target == null ? backbuffer.scale : 1);
            var h = cmdClip.h * (target == null ? backbuffer.scale : 1);

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            glScissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));
        }

        // Set the blending
        if (_command.blending)
        {
            glEnable(GL_BLEND);
            glBlendFuncSeparate(
                _command.srcRGB.getBlendMode(),
                _command.dstRGB.getBlendMode(),
                _command.srcAlpha.getBlendMode(),
                _command.dstAlpha.getBlendMode());
        }
        else
        {
            glDisable(GL_BLEND);
        }

        // Update shader blocks and bind any textures required.
        setUniforms(_command);
    }

    /**
     * Apply all of a shaders uniforms.
     * @param _command     Command to set the state for.
     * @param _enableStats If stats are to be recorded.
     */
    function setUniforms(_command : DrawCommand)
    {
        var cache = shaderUniforms.get(_command.shader.id);
        // var preferedUniforms = _command.uniforms.or(_command.shader.uniforms);

        // TEMP : Set all textures all the time.
        // TODO : Store all bound texture IDs and check before binding textures.

        if (cache.layout.textures.length <= _command.textures.length)
        {
            // See how many texture actually need changing
            var toChange = 0;
            for (i in 0..._command.textures.length)
            {
                // Handle samplers quickly, for now...

                // Get / create and bind the sampler for the current texture.
                var currentSampler = defaultSampler;
                if (_command.samplers[i] != null)
                {
                    var samplerHash     = _command.samplers[i].hash();
                    var textureSamplers = samplerObjects[_command.textures[i].id];

                    if (!textureSamplers.exists(samplerHash))
                    {
                        textureSamplers[samplerHash] = createSamplerObject(_command.samplers[i]);
                    }

                    currentSampler = textureSamplers[samplerHash];
                }
                
                glBindSampler(i, currentSampler);

                // see if textures need updating.
                var tex = textureObjects.get(_command.textures[i].id);
                if (tex != textureSlots[i])
                {
                    textureSlots[i] = tex;

                    toChange++;
                }
            }

            // If we need to update textures just re-bind them all for ease of gl api use.
            if (toChange > 0)
            {
                glBindTextures(0, _command.textures.length, textureSlots);
            }
        }
        else
        {
            throw 'OpenGL 4.5 Backend Exception : ${_command.shader.id} : More textures required by the shader than are provided by the draw command';
        }
        
        for (i in 0...cache.layout.blocks.length)
        {
            if (cache.layout.blocks[i].name == 'defaultMatrices')
            {
                buildCameraMatrices(_command.camera);

                var view       = _command.camera.view;
                var projection = _command.camera.projection;

                // The matrix ssbo used depends on if its a static or stream command
                // stream draws are batched and only have a single model matrix, they use the shaders default matrix ssbo.
                // static draws have individual ssbos for each command. These ssbos fit a model matrix per geometry.
                // The matrix buffer for static draws is uploaded in the static draw manager.
                // 
                // TODO : have static buffer draws use the default shader ssbo?
                // switch _command.uploadType
                // {
                //     case Static:
                //         var rng = null; // staticStorage.get(_command);
                //         var ptr = Pointer.arrayElem(rng.matrixBuffer.bytes.getData(), 0);
                //         Stdlib.memcpy(ptr          , (projection : Float32BufferData).bytes.getData().address((projection : Float32BufferData).byteOffset), 64);
                //         Stdlib.memcpy(ptr.incBy(64), (view       : Float32BufferData).bytes.getData().address((view       : Float32BufferData).byteOffset), 64);
                //         glNamedBufferSubData(rng.glMatrixBuffer, 0, rng.matrixBuffer.length, rng.matrixBuffer.bytes.getData());

                //         if (ssbo != rng.glMatrixBuffer)
                //         {
                //             glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cache.blockBindings[i], rng.glMatrixBuffer);
                //             ssbo = rng.glMatrixBuffer;
                //         }
                //         if (cmds != rng.glCommandBuffer)
                //         {
                //             glBindBuffer(GL_DRAW_INDIRECT_BUFFER, rng.glCommandBuffer);
                //             cmds = rng.glCommandBuffer;
                //         }
                        
                //     case Stream, Immediate:
                //         var ptr   = Pointer.arrayElem(cache.blockBytes[i].getData(), 0);
                //         var model = null; // streamStorage.getModelMatrix(_command.id);
                //         Stdlib.memcpy(ptr          , (projection : Float32BufferData).bytes.getData().address((projection : Float32BufferData).byteOffset), 64);
                //         Stdlib.memcpy(ptr.incBy(64), (view       : Float32BufferData).bytes.getData().address((view       : Float32BufferData).byteOffset), 64);
                //         Stdlib.memcpy(ptr.incBy(64), (model      : Float32BufferData).bytes.getData().address((model      : Float32BufferData).byteOffset), 64);
                //         glNamedBufferSubData(cache.blockBuffers[i], 0, cache.blockBytes[i].length, cache.blockBytes[i].getData());

                //         if (ssbo != cache.blockBuffers[i])
                //         {
                //             glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cache.blockBindings[i], cache.blockBuffers[i]);
                //             ssbo = cache.blockBuffers[i];
                //         }
                // }
            }
            else
            {
                var ptr : Pointer<UInt8> = Pointer.arrayElem(cache.blockBytes[i].getData(), 0).reinterpret();

                // Otherwise upload all user specified uniform values.
                // TODO : We should have some sort of error checking if the expected uniforms are not found.
                var pos = 0;
                for (val in cache.layout.blocks[i].values)
                {
                    // switch val.type
                    // {
                    //     case Matrix4:
                    //         var mat = preferedUniforms.matrix4.exists(val.name) ? preferedUniforms.matrix4.get(val.name) : _command.shader.uniforms.matrix4.get(val.name);
                    //         Stdlib.memcpy(ptr.incBy(pos), (mat : Float32BufferData).bytes.getData().address((mat : Float32BufferData).byteOffset), 64);
                    //         pos += 64;
                    //     case Vector4:
                    //         var vec = preferedUniforms.vector4.exists(val.name) ? preferedUniforms.vector4.get(val.name) : _command.shader.uniforms.vector4.get(val.name);
                    //         Stdlib.memcpy(ptr.incBy(pos), (vec : Float32BufferData).bytes.getData().address((vec : Float32BufferData).byteOffset), 16);
                    //         pos += 16;
                    //     case Int:
                    //         var dst : Pointer<Int32> = ptr.reinterpret();
                    //         dst.setAt(Std.int(pos / 4), preferedUniforms.int.exists(val.name) ? preferedUniforms.int.get(val.name) : _command.shader.uniforms.int.get(val.name));
                    //         pos += 4;
                    //     case Float:
                    //         var dst : Pointer<Float32> = ptr.reinterpret();
                    //         dst.setAt(Std.int(pos / 4), preferedUniforms.float.exists(val.name) ? preferedUniforms.float.get(val.name) : _command.shader.uniforms.float.get(val.name));
                    //         pos += 4;
                    // }
                }

                glNamedBufferSubData(cache.blockBuffers[i], 0, cache.blockBytes[i].length, cache.blockBytes[i].getData());
                glBindBufferBase(GL_SHADER_STORAGE_BUFFER, cache.blockBindings[i], cache.blockBuffers[i]);
            }
        }
    }

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

    function buildCameraMatrices(_camera : Camera)
    {
        switch _camera.type
        {
            case Orthographic:
                var orth = (cast _camera : Camera2D);
                if (orth.dirty)
                {
                    orth.projection.makeHeterogeneousOrthographic(0, orth.viewport.w, orth.viewport.h, 0, -100, 100);
                    orth.view.copy(orth.transformation.world.matrix).invert();
                    orth.dirty = false;
                }
            case Projection:
                var proj = (cast _camera : Camera3D);
                if (proj.dirty)
                {
                    proj.projection.makeHeterogeneousPerspective(proj.fov, proj.aspect, proj.near, proj.far);
                    proj.projection.scale(perspectiveYFlipVector);
                    proj.view.copy(proj.transformation.world.matrix).invert();
                    proj.dirty = false;
                }
            case Custom:
                // Do nothing, user is responsible for building their custom camera matrices.
        }
    }

    function createBackbuffer(_width : Int, _height : Int, _remove : Bool = true) : BackBuffer
    {
        if (_remove)
        {
            glDeleteTextures(1, [ backbuffer.texture ]);
            glDeleteRenderbuffers(1, [ backbuffer.depthStencil ]);
            glDeleteFramebuffers(1, [ backbuffer.framebuffer ]);
        }

        var tex = [ 0 ];
        glCreateTextures(GL_TEXTURE_2D, 1, tex);
        glTextureStorage2D(tex[0], 1, GL_RGB8, _width, _height);

        var rbo = [ 0 ];
        glCreateRenderbuffers(1, rbo);
        glNamedRenderbufferStorage(rbo[0], GL_DEPTH24_STENCIL8, _width, _height);

        var fbo = [ 0 ];
        glCreateFramebuffers(1, fbo);
        glNamedFramebufferTexture(fbo[0], GL_COLOR_ATTACHMENT0, tex[0], 0);
        glNamedFramebufferRenderbuffer(fbo[0], GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo[0]);

        if (glCheckNamedFramebufferStatus(fbo[0], GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            throw 'unable to create framebuffer';
        }

        if (target == null)
        {
            glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
        }

        return new BackBuffer(_width, _height, 1, tex[0], rbo[0], fbo[0]);
    }

    // #endregion
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
     * Binding point of all shader blocks.
     */
    public final blockBindings : Array<Int>;

    /**
     * SSBO buffer objects.
     */
    public final blockBuffers : Array<Int>;

    /**
     * Bytes for each SSBO buffer.
     */
    public final blockBytes : Array<Bytes>;

    public function new(_layout : ShaderLayout, _textureLocations : Array<Int>, _blockBindings : Array<Int>, _blockBuffers : Array<Int>, _blockBytes : Array<Bytes>)
    {
        layout           = _layout;
        textureLocations = _textureLocations;
        blockBindings    = _blockBindings;
        blockBuffers     = _blockBuffers;
        blockBytes       = _blockBytes;
    }
}
