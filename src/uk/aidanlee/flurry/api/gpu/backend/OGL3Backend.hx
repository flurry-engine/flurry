package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.gpu.state.TargetState;
import cpp.UInt8;
import haxe.Exception;
import haxe.io.Float32Array;
import haxe.io.UInt16Array;
import cpp.Pointer;
import cpp.Stdlib.memcpy;
import opengl.GL.*;
import opengl.WebGL.getShaderParameter;
import opengl.WebGL.shaderSource;
import opengl.WebGL.getProgramParameter;
import opengl.WebGL.getProgramInfoLog;
import opengl.WebGL.getShaderInfoLog;
import sdl.Window;
import sdl.GLContext;
import sdl.SDL;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.camera.Camera3D;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderBlock;
import uk.aidanlee.flurry.api.resources.ResourceEvents;

using Safety;
using Lambda;
using cpp.NativeArray;
using uk.aidanlee.flurry.utils.opengl.GLConverters;

/**
 * WebGL backend written against the webGL 1.0 spec (openGL ES 2.0).
 * Uses snows openGL module so it can run on desktops and web platforms.
 * Allows targeting web, osx, and older integrated GPUs (anywhere where openGL 4.5 isn't supported).
 */
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
    final glVertexVbo : Int;

    /**
     * The ubo used to store all matrix data.
     */
    final glMatrixUbo : Int;

    /**
     * The single index buffer used by the backend.
     */
    final glIbo : Int;

    /**
     * Vertex buffer used by this backend.
     */
    final vertexBuffer : Float32Array;

    /**
     * Index buffer used by this backend.
     */
    final indexBuffer : UInt16Array;

    /**
     * Buffer used to store model, view, and projection matrices for all draws.
     */
    final matrixBuffer : Float32Array;

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
     * Constant vector which will be used to flip perspective cameras on their y axis.
     */
    final perspectiveYFlipVector : Vector3;

    /**
     * Array of opengl textures objects which will be bound.
     * Size of this array is equal to the max number of texture bindings allowed .
     */
    final textureSlots : Array<Int>;

    /**
     * The default sampler object to use if no sampler is provided.
     */
    final defaultSampler : Int;

    /**
     * Number of bytes for each mvp matrix range.
     * Includes padding for ubo alignment.
     */
    final matrixRangeSize : Int;

    /**
     * Queue all draw commands will be placed into.
     */
    final commandQueue : Array<GeometryDrawCommand>;

    /**
     * Backbuffer display, default target if none is specified.
     */
    var backbuffer : BackBuffer;

    // GL state variables

    var target   : TargetState;
    var shader   : ShaderResource;
    var clip     : Rectangle;
    var viewport : Rectangle;

    // SDL Window and GL Context

    var window : Window;

    var glContext : GLContext;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        resourceEvents = _resourceEvents;
        displayEvents  = _displayEvents;

        createWindow(_windowConfig);

        shaderPrograms     = [];
        shaderUniforms     = [];
        textureObjects     = [];
        samplerObjects     = [];
        framebufferObjects = [];

        perspectiveYFlipVector = new Vector3(1, -1, 1);

        // Create and bind a singular VBO.
        // Only needs to be bound once since it is used for all drawing.
        vertexBuffer = new Float32Array((_rendererConfig.dynamicVertices + _rendererConfig.unchangingVertices) * 9);
        indexBuffer  = new UInt16Array(_rendererConfig.dynamicIndices + _rendererConfig.unchangingIndices);
        matrixBuffer = new Float32Array((_rendererConfig.dynamicVertices + _rendererConfig.unchangingVertices));

        // Core OpenGL profiles require atleast one VAO is bound.
        var vao = [ 0 ];
        glGenVertexArrays(1, vao);
        glBindVertexArray(vao[0]);

        // Create two vertex buffers
        var vbos = [ 0, 0 ];
        glGenBuffers(vbos.length, vbos);
        glVertexVbo = vbos[0];
        glMatrixUbo = vbos[1];

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);
        glEnableVertexAttribArray(3);

        glBindBuffer(GL_ARRAY_BUFFER, glMatrixUbo);
        glBufferData(GL_ARRAY_BUFFER, matrixBuffer.view.byteLength, matrixBuffer.view.buffer.getData(), GL_DYNAMIC_DRAW);

        // Vertex data will be interleaved, sourced from the first vertex buffer.
        glBindBuffer(GL_ARRAY_BUFFER, glVertexVbo);
        glBufferData(GL_ARRAY_BUFFER, vertexBuffer.view.byteLength, vertexBuffer.view.buffer.getData(), GL_DYNAMIC_DRAW);

        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 0, 3, GL_FLOAT, false, VERTEX_BYTE_SIZE, VERTEX_OFFSET_POS);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 1, 4, GL_FLOAT, false, VERTEX_BYTE_SIZE, VERTEX_OFFSET_COL);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 2, 2, GL_FLOAT, false, VERTEX_BYTE_SIZE, VERTEX_OFFSET_TEX);

        // Setup index buffer.
        var ibos = [ 0 ];
        glGenBuffers(1, ibos);
        glIbo = ibos[0];

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIbo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBuffer.view.byteLength, indexBuffer.view.buffer.getData(), GL_DYNAMIC_DRAW);

        var samplers = [ 0 ];
        glGenSamplers(1, samplers);
        defaultSampler = samplers[0];
        glSamplerParameteri(defaultSampler, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glSamplerParameteri(defaultSampler, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // default state
        viewport     = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        clip         = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        shader       = null;
        target       = Backbuffer;
        textureSlots = [ for (_ in 0...GL_MAX_TEXTURE_IMAGE_UNITS) 0 ];

        // Create our own custom backbuffer.
        // we blit a flipped version to the actual backbuffer before swapping.
        backbuffer = createBackbuffer(_windowConfig.width, _windowConfig.height, false);

        // Default blend mode
        // TODO : Move this to be a settable property in the geometry or renderer or something
        glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);

        // Set the clear colour
        glClearColor(_rendererConfig.clearColour.r, _rendererConfig.clearColour.g, _rendererConfig.clearColour.b, _rendererConfig.clearColour.a);

        // Default scissor test
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        resourceEvents.created.add(onResourceCreated);
        resourceEvents.removed.add(onResourceRemoved);
        displayEvents.sizeChanged.add(onSizeChanged);
        displayEvents.changeRequested.add(onChangeRequest);

        // Get UBO size and alignment
        var maxUboSize = [ 0 ];
        glGetIntegerv(GL_MAX_UNIFORM_BLOCK_SIZE, maxUboSize);

        var uboAlignment = [ 0 ];
        glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, uboAlignment);

        // var matricesPerBatch   = Std.int(Maths.min(maxUboSize[0] / 64, 65535));

        matrixRangeSize = BYTES_PER_DRAW_MATRICES + Std.int(Maths.max(uboAlignment[0] - BYTES_PER_DRAW_MATRICES, 0));
        commandQueue    = [];
    }

    /**
     * Clear the backbuffer and empty the command queue.
     */
    public function preDraw()
    {
        target = Backbuffer;
        clip.set(0, 0, backbuffer.width, backbuffer.height);

        glScissor(0, 0, backbuffer.width, backbuffer.height);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

        commandQueue.resize(0);
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function queue(_command : GeometryDrawCommand)
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
        uploadGeometryData();
        uploadMatrixData();
        drawCommands();
    }

    public function postDraw()
    {
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, backbuffer.framebuffer);

        glBlitFramebuffer(
            0, 0, backbuffer.width, backbuffer.height,
            0, backbuffer.height, backbuffer.width, 0,
            GL_COLOR_BUFFER_BIT, GL_NEAREST);

        glBindFramebuffer(GL_FRAMEBUFFER, backbuffer.framebuffer);

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
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
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
     * Creates a shader from a vertex and fragment source.
     * @param _vert   Vertex shader source.
     * @param _frag   Fragment shader source.
     * @param _layout Shader layout JSON description.
     * @return Shader
     */
    function createShader(_resource : ShaderResource)
    {
        if (shaderPrograms.exists(_resource.id))
        {
            return;
        }

        if (_resource.ogl3 == null)
        {
            throw new GL32NoShaderSourceException(_resource.id);
        }

        // Create vertex shader.
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        shaderSource(vertex, _resource.ogl3.vertex.toString());
        glCompileShader(vertex);

        if (getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw new GL32VertexCompilationError(_resource.id, getShaderInfoLog(vertex));
        }

        // Create fragment shader.
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        shaderSource(fragment, _resource.ogl3.fragment.toString());
        glCompileShader(fragment);

        if (getShaderParameter(fragment, GL_COMPILE_STATUS) == 0)
        {
            throw new GL32FragmentCompilationError(_resource.id, getShaderInfoLog(vertex));
        }

        // Link the shaders into a program.
        var program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);

        if (getProgramParameter(program, GL_LINK_STATUS) == 0)
        {
            throw new GL32ShaderLinkingException(_resource.id, getProgramInfoLog(program));
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

        // Generate gl buffers and haxe byte objects for all our blocks

        var blockBuffers = [ for (i in 0..._resource.layout.blocks.length) 0 ];
        glGenBuffers(blockBuffers.length, blockBuffers);
        var blockSizes = [ for (i in 0..._resource.layout.blocks.length) generateUniformBlock(_resource.layout.blocks[i], blockBuffers[i], blockBindings[i]) ];

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderLocations(_resource.layout, textureLocations, blockBindings, blockBuffers, blockSizes));
    }

    /**
     * Removes and frees the resources used by a shader.
     * @param _name Name of the shader.
     */
    function removeShader(_resource : ShaderResource)
    {
        glDeleteProgram(shaderPrograms.get(_resource.id));

        shaderPrograms.remove(_resource.id);
        shaderUniforms.remove(_resource.id);
    }

    /**
     * Creates a new texture given an array of pixel data.
     * @param _name   Name of the texture/
     * @param _pixels Pixel data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
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

    /**
     * Removes and frees the resources used by a texture.
     * @param _name Name of the texture.
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

    /**
     * Calculates the size of a shader block, creates the OpenGL object, and returns haxe bytes of the needed size.
     * @param _block   Shader block to initialise.
     * @param _buffer  OpenGL UBO buffer ID.
     * @param _binding OpenGL UBO binding position.
     * @return Bytes
     */
    function generateUniformBlock(_block : ShaderBlock, _buffer : Int, _binding : Int) : Int
    {
        var blockSize = 0;
        for (val in _block.values)
        {
            switch val.type
            {
                case Matrix4: blockSize += BYTES_PER_MATRIX;
                case Vector4: blockSize += 16;
                case Int, Float: blockSize += 4;
            }
        }

        glBindBuffer(GL_UNIFORM_BUFFER, _buffer);
        untyped __cpp__('glBufferData(GL_UNIFORM_BUFFER, {0}, nullptr, GL_DYNAMIC_DRAW)', blockSize);

        return blockSize;
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
        final vtxDst = vertexBuffer.view.buffer.getData().address(0);
        final idxDst = indexBuffer.view.buffer.getData().address(0);

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

        glBufferSubData(GL_ARRAY_BUFFER, 0, vtxUploaded, vertexBuffer.view.buffer.getData());
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, idxUploaded, indexBuffer.view.buffer.getData());
    }

    function uploadMatrixData()
    {
        glBindBuffer(GL_UNIFORM_BUFFER, glMatrixUbo);

        final matDst = matrixBuffer.view.buffer.getData().address(0);

        var bytesUploaded = 0;

        for (command in commandQueue)
        {
            buildCameraMatrices(command.camera);

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

        glBufferSubData(GL_UNIFORM_BUFFER, 0, bytesUploaded, matrixBuffer.view.buffer.getData());
    }

    /**
     * Iterate over all uniform blobs provided by the command and update its UBO.
     * Uniform blobs and their blocks are matched by their name.
     * An exception will be thrown if it cannot find a matching block.
     * @param _command Command to pull uniforms from.
     */
    function uploadUniformData(_command : GeometryDrawCommand)
    {
        // Upload uniform data
        final cache = shaderUniforms.get(_command.shader.id);

        for (block in _command.uniforms)
        {
            final index = findBlockIndexByName(block.name, cache.layout.blocks);

            glBindBuffer(GL_UNIFORM_BUFFER, cache.blockBuffers[index]);

            final dst : Pointer<UInt8> = Pointer
                .fromRaw(glMapBufferRange(GL_UNIFORM_BUFFER, 0, cache.blockSizes[index], GL_MAP_WRITE_BIT | GL_MAP_INVALIDATE_RANGE_BIT))
                .reinterpret();

            memcpy(
                dst,
                block.buffer.bytes.getData().address(0),
                cache.blockSizes[index]);

            glUnmapBuffer(GL_UNIFORM_BUFFER);
        }
    }

    /**
     * Loop over all commands and issue draw calls for them.
     * 
     */
    function drawCommands()
    {
        var matOffset = 0;
        var idxOffset = 0;
        var vtxOffset = 0;

        // Draw the queued commands
        for (command in commandQueue)
        {
            // Change the state so the vertices are drawn correctly.
            uploadUniformData(command);
            setState(command);

            for (geometry in command.geometry)
            {
                glBindBufferRange(GL_UNIFORM_BUFFER, 0, glMatrixUbo, matOffset, 192);

                switch geometry.data {
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
                        final numVertices = Std.int(_vertices.buffer.byteLength / VERTEX_BYTE_SIZE);

                        glDrawArrays(command.primitive.getPrimitiveType(), vtxOffset, numVertices);

                        vtxOffset += numVertices;
                }

                matOffset += matrixRangeSize;
            }
        }
    }

    // #endregion

    // #region State Management

    /**
     * Update the openGL state so it can draw the provided command.
     * @param _command      Command to set the state for.
     */
    function setState(_command : DrawCommand)
    {
        // Either sets the framebuffer to the backbuffer or to an uploaded texture.
        // If the texture has not yet had a framebuffer generated for it, it is done on demand.
        // This could be something which is done on texture creation in the future.
        switch _command.target
        {
            case Backbuffer:
                switch target
                {
                    case Backbuffer: // no change in target
                    case Texture(_requested):
                        bindTextureFramebuffer(_requested);
                }
            case Texture(_current):
                switch target
                {
                    case Backbuffer:
                        glBindFramebuffer(GL_FRAMEBUFFER, backbuffer.framebuffer);
                    case Texture(_requested):
                        if (_current != _requested)
                        {
                            bindTextureFramebuffer(_requested);
                        }
                }
        }
        target = _command.target;

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

        // If the camera does not specify a viewport (non orthographic) then the full size of the target is used.
        switch _command.camera.viewport {
            case None:
                switch target {
                    case Backbuffer:
                        glViewport(0, 0, backbuffer.width, backbuffer.height);
                    case Texture(_image):
                        glViewport(0, 0, _image.width, _image.height);
                }
            case Viewport(_x, _y, _width, _height):
                glViewport(_x, _y, _width, _height);
        }

        // If the camera does not specify a clip rectangle then the full size of the target is used.
        switch _command.clip
        {
            case None:
                switch target
                {
                    case Backbuffer:
                        glScissor(0, 0, backbuffer.width, backbuffer.height);
                    case Texture(_image):
                        glScissor(0, 0, _image.width, _image.height);
                }
            case Clip(_x, _y, _width, _height):
                glScissor(_x, _y, _width, _height);
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

        // Apply the shaders uniforms
        // TODO : Only set uniforms if the value has changed.
        setTextures(_command);

        final cache = shaderUniforms.get(_command.shader.id);
        for (i in 0...cache.layout.blocks.length)
        {
            if (cache.layout.blocks[i].name != 'flurry_matrices')
            {
                glBindBufferBase(GL_UNIFORM_BUFFER, cache.blockBindings[i], cache.blockBuffers[i]);
            }
        }
    }

    /**
     * Apply all of a shaders uniforms.
     * @param _combined Only required uniform. VP combined matrix.
     */
    function setTextures(_command : DrawCommand)
    {
        // Find this shaders location cache.
        final cache = shaderUniforms.get(_command.shader.id);

        // Bind textures and samplers.
        if (cache.layout.textures.length <= _command.textures.length)
        {
            // then go through each texture and bind it if it isn't already.
            for (i in 0..._command.textures.length)
            {
                // Bind the texture if its not already bound.
                var glTextureID  = textureObjects.get(_command.textures[i].id);
                if (glTextureID != textureSlots[i])
                {
                    glActiveTexture(GL_TEXTURE0 + i);
                    glBindTexture(GL_TEXTURE_2D, glTextureID);

                    textureSlots[i] = glTextureID;
                }

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
            }
        }
        else
        {
            throw new GL32NotEnoughTexturesException(_command.shader.id, _command.id, cache.layout.textures.length, _command.textures.length);
        }
    }

    function bindTextureFramebuffer(_image : ImageResource)
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
                throw new GL32IncompleteFramebufferException(_image.id);
            }

            framebufferObjects.set(_image.id, fbo[0]);

            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }

        glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects.get(_image.id));
    }

    // #endregion

    function buildCameraMatrices(_camera : Camera)
    {
        switch _camera.type
        {
            case Orthographic:
                var orth = (cast _camera : Camera2D);
                if (orth.dirty)
                {
                    switch orth.viewport
                    {
                        case None:
                            orth.projection.makeHomogeneousOrthographic(0, orth.size.x, orth.size.y, 0, -100, 100);
                        case Viewport(_, _, _width, _height):
                            orth.projection.makeHomogeneousOrthographic(0, _width, _height, 0, -100, 100);
                    }

                    orth.view.copy(orth.transformation.world.matrix).invert();
                    orth.dirty = false;
                }
            case Projection:
                var proj = (cast _camera : Camera3D);
                if (proj.dirty)
                {
                    proj.projection.makeHomogeneousPerspective(proj.fov, proj.aspect, proj.near, proj.far);
                    proj.projection.scale(perspectiveYFlipVector);
                    proj.view.copy(proj.transformation.world.matrix).invert();
                    proj.dirty = false;
                }
            case Custom:
                // Do nothing, user is responsible for building their custom camera matrices.
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
            throw new GL32IncompleteFramebufferException('backbuffer');
        }

        // Cleanup / reset state after setting up new framebuffer.
        switch target
        {
            case Backbuffer:
                glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
            case Texture(_image):
                glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects.get(_image.id));
        }

        for (i in 0...textureSlots.length) textureSlots[i] = 0;

        return new BackBuffer(_width, _height, 1, tex[0], rbo[0], fbo[0]);
    }

    function findBlockIndexByName(_name : String, _blocks : Array<ShaderBlock>) : Int
    {
        for (i in 0..._blocks.length)
        {
            if (_blocks[i].name == _name)
            {
                return i;
            }
        }

        throw new GL32UniformBlockNotFoundException(_name);
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

    /**
     * SSBO buffer objects.
     */
    public final blockBuffers : Array<Int>;

    /**
     * Size in bytes of all blocks.
     */
    public final blockSizes : Array<Int>;

    public function new(_layout : ShaderLayout, _textureLocations : Array<Int>, _blockBindings : Array<Int>, _blockBuffers : Array<Int>, _blockSizes : Array<Int>)
    {
        layout           = _layout;
        textureLocations = _textureLocations;
        blockBindings    = _blockBindings;
        blockBuffers     = _blockBuffers;
        blockSizes       = _blockSizes;
    }
}

private class GL32NoShaderSourceException extends Exception
{
    public function new(_id : String)
    {
        super('$_id does not contain source code for a openGL 3.2 shader');
    }
}

private class GL32VertexCompilationError extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to compile the vertex shader for $_id : $_error');
    }
}

private class GL32FragmentCompilationError extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to compile the fragment shader for $_id : $_error');
    }
}

private class GL32ShaderLinkingException extends Exception
{
    public function new(_id : String, _error : String)
    {
        super('Unable to link a shader from $_id : $_error');
    }
}

private class GL32IncompleteFramebufferException extends Exception
{
    public function new(_error : String)
    {
        super(_error);
    }
}

private class GL32NotEnoughTexturesException extends Exception
{
    public function new(_shaderID : String, _drawCommandID : Int, _expected : Int, _actual : Int)
    {
        super('Shader $_shaderID expects $_expected textures but the draw command $_drawCommandID only provided $_actual');
    }
}

private class GL32UniformBlockNotFoundException extends Exception
{
    public function new(_blockName)
    {
        super('Unable to find a uniform block with the name $_blockName');
    }
}
