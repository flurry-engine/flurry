package uk.aidanlee.flurry.api.gpu.backend;

import haxe.io.Bytes;
import haxe.Exception;
import haxe.io.UInt8Array;
import haxe.io.Float32Array;
import haxe.io.UInt16Array;
import cpp.UInt16;
import cpp.Float32;
import cpp.Int32;
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
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.Resource.ShaderType;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderBlock;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.thread.JobQueue;

using Safety;
using cpp.NativeArray;
using uk.aidanlee.flurry.utils.opengl.GLConverters;

/**
 * WebGL backend written against the webGL 1.0 spec (openGL ES 2.0).
 * Uses snows openGL module so it can run on desktops and web platforms.
 * Allows targeting web, osx, and older integrated GPUs (anywhere where openGL 4.5 isn't supported).
 */
class OGL3Backend implements IRendererBackend
{
    static final RENDERER_THREADS = #if flurry_ogl3_no_multithreading 1 #else Std.int(Maths.max(SDL.getCPUCount() - 2, 1)) #end;

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
     * Access to the renderer who owns this backend.
     */
    final rendererStats : RendererStats;

    /**
     * The single VBO used by the backend.
     */
    final glVbo : Int;

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
     * Transformation vector used for transforming geometry vertices by a matrix.
     */
    final transformationVectors : Array<Vector>;

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
     * Framebuffer objects keyed by their associated image resource IDs.
     * Framebuffers will only be generated when an image resource is used as a target.
     * Will be destroyed when the associated image resource is destroyed.
     */
    final framebufferObjects : Map<String, Int>;

    /**
     * Job queue for multi-threaded geometry uploading.
     */
    final jobQueue : JobQueue;

    /**
     * dummy identity matrix for passing into shaders so they have parity with OGL4 shaders.
     */
    final dummyModelMatrix : Matrix;

    /**
     * Constant vector which will be used to flip perspective cameras on their y axis.
     */
    final perspectiveYFlipVector : Vector;

    /**
     * Array of opengl textures objects which will be bound.
     * Size of this array is equal to the max number of texture bindings allowed .
     */
    final textureSlots : Array<Int>;

    /**
     * Backbuffer display, default target if none is specified.
     */
    var backbuffer : BackBuffer;

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

    /**
     * Map of command IDs and the vertex offset into the buffer.
     */
    var commandVtxOffsets : Map<Int, Int>;

    /**
     * Map of command IDs and the index offset into the buffer.
     */
    var commandIdxOffsets : Map<Int, Int>;

    /**
     * Map of all the model matices to transform buffer commands.
     */
    var bufferModelMatrix : Map<Int, Matrix>;

    // GL state variables

    var target   : ImageResource;
    var shader   : ShaderResource;
    var clip     : Rectangle;
    var viewport : Rectangle;

    // SDL Window and GL Context

    var window : Window;

    var glContext : GLContext;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _rendererStats : RendererStats, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        resourceEvents = _resourceEvents;
        displayEvents  = _displayEvents;
        rendererStats  = _rendererStats;

        createWindow(_windowConfig);

        shaderPrograms     = [];
        shaderUniforms     = [];
        textureObjects     = [];
        framebufferObjects = [];

        perspectiveYFlipVector = new Vector(1, -1, 1);
        dummyModelMatrix       = new Matrix();
        jobQueue               = new JobQueue(RENDERER_THREADS);
        transformationVectors  = [ for (_ in 0...RENDERER_THREADS) new Vector() ];
        commandVtxOffsets      = [];
        commandIdxOffsets      = [];

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;

        // Create and bind a singular VBO.
        // Only needs to be bound once since it is used for all drawing.
        vertexBuffer = new Float32Array((_rendererConfig.dynamicVertices + _rendererConfig.unchangingVertices) * VERTEX_FLOAT_SIZE);
        indexBuffer  = new UInt16Array(_rendererConfig.dynamicIndices + _rendererConfig.unchangingIndices);

        // Core OpenGL profiles require atleast one VAO is bound.
        var vao = [ 0 ];
        glGenVertexArrays(1, vao);
        glBindVertexArray(vao[0]);

        var vbos = [ 0 ];
        glGenBuffers(1, vbos);
        glVbo = vbos[0];

        glBindBuffer(GL_ARRAY_BUFFER, glVbo);
        glBufferData(GL_ARRAY_BUFFER, vertexBuffer.view.byteLength, vertexBuffer.view.buffer.getData(), GL_DYNAMIC_DRAW);

        var ibos = [ 0 ];
        glGenBuffers(1, ibos);
        glIbo = ibos[0];

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIbo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBuffer.view.byteLength, indexBuffer.view.buffer.getData(), GL_DYNAMIC_DRAW);

        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 0, 3, GL_FLOAT, false, VERTEX_FLOAT_SIZE * Float32Array.BYTES_PER_ELEMENT, Float32Array.BYTES_PER_ELEMENT * VERTEX_OFFSET_POS);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 1, 4, GL_FLOAT, false, VERTEX_FLOAT_SIZE * Float32Array.BYTES_PER_ELEMENT, Float32Array.BYTES_PER_ELEMENT * VERTEX_OFFSET_COL);
        untyped __cpp__('glVertexAttribPointer({0}, {1}, {2}, {3}, {4}, (void*)(intptr_t){5})', 2, 2, GL_FLOAT, false, VERTEX_FLOAT_SIZE * Float32Array.BYTES_PER_ELEMENT, Float32Array.BYTES_PER_ELEMENT * VERTEX_OFFSET_TEX);

        // default state
        viewport     = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        clip         = new Rectangle(0, 0, _windowConfig.width, _windowConfig.height);
        shader       = null;
        target       = null;
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
    }

    public function preDraw()
    {
        target = null;
        clip.set(0, 0, backbuffer.width, backbuffer.height);

        glScissor(0, 0, backbuffer.width, backbuffer.height);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        indexOffset       = 0;
        commandVtxOffsets = [];
        commandIdxOffsets = [];
        bufferModelMatrix = [];
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void
    {
        var vtxDst : Pointer<Float32> = Pointer.fromRaw(glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY)).reinterpret();
        var idxDst : Pointer<UInt16>  = Pointer.fromRaw(glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY)).reinterpret();

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
                    vtxWriteOffset += command.geometry[j].vertices.length * VERTEX_FLOAT_SIZE;
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
                vertexOffset      += geom.vertices.length;
                vertexFloatOffset += geom.vertices.length * VERTEX_FLOAT_SIZE;
                indexOffset       += geom.indices.length;
            }

            jobQueue.wait();
        }

        glUnmapBuffer(GL_ARRAY_BUFFER);
        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
    }

    /**
     * Upload buffer data to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>) : Void
    {
        var idxDst : Pointer<UInt16>  = Pointer.fromRaw(glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY)).reinterpret();
        var vtxDst : Pointer<Float32> = Pointer.fromRaw(glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY)).reinterpret();

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

        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
        glUnmapBuffer(GL_ARRAY_BUFFER);
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
            // Change the state so the vertices are drawn correctly.
            setState(command, !_recordStats);

            // Draw the actual vertices
            if (command.indices > 0)
            {
                var idxOffset = commandIdxOffsets.get(command.id) * 2;
                var vtxOffset = commandVtxOffsets.get(command.id);
                untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', command.primitive.getPrimitiveType(), command.indices, GL_UNSIGNED_SHORT, idxOffset, vtxOffset);
            }
            else
            {
                var vtxOffset = commandVtxOffsets.get(command.id);
                glDrawArrays(command.primitive.getPrimitiveType(), vtxOffset, command.vertices);
            }      

            // Record stats about this draw call.
            if (_recordStats)
            {
                rendererStats.dynamicDraws++;
                rendererStats.totalVertices += command.vertices;
            }
        }
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

        window    = SDL.createWindow('Flurry', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
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
        var blockBindings    = [ for (i in 0..._resource.layout.blocks.length) _resource.layout.blocks[i].bind ];

        for (i in 0..._resource.layout.blocks.length)
        {
            glUniformBlockBinding(program, blockLocations[i], blockBindings[i]);
        }

        // Generate gl buffers and haxe byte objects for all our blocks

        var blockBuffers = [ for (i in 0..._resource.layout.blocks.length) 0 ];
        glGenBuffers(blockBuffers.length, blockBuffers);
        var blockBytes = [ for (i in 0..._resource.layout.blocks.length) generateUniformBlock(_resource.layout.blocks[i], blockBuffers[i], blockBindings[i]) ];

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderLocations(_resource.layout, textureLocations, blockLocations, blockBuffers, blockBytes));
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
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _resource.width, _resource.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, UInt8Array.fromArray(cast _resource.pixels).getData().bytes.getData());

        glBindTexture(GL_TEXTURE_2D, 0);

        textureObjects.set(_resource.id, id[0]);
    }

    /**
     * Removes and frees the resources used by a texture.
     * @param _name Name of the texture.
     */
    function removeTexture(_resource : ImageResource)
    {
        glDeleteTextures(1, [ textureObjects.get(_resource.id) ]);
        textureObjects.remove(_resource.id);
    }

    /**
     * Calculates the size of a shader block, creates the OpenGL object, and returns haxe bytes of the needed size.
     * @param _block   Shader block to initialise.
     * @param _buffer  OpenGL UBO buffer ID.
     * @param _binding OpenGL UBO binding position.
     * @return Bytes
     */
    function generateUniformBlock(_block : ShaderBlock, _buffer : Int, _binding : Int) : Bytes
    {
        var blockSize = 0;
        for (val in _block.vals)
        {
            switch (ShaderType.createByName(val.type))
            {
                case Matrix4: blockSize += 64;
                case Vector4: blockSize += 16;
                case Int, Float: blockSize += 4;
            }
        }

        var bytes = Bytes.alloc(blockSize);

        glBindBuffer(GL_UNIFORM_BUFFER, _buffer);
        glBufferData(GL_UNIFORM_BUFFER, blockSize, bytes.getData(), GL_DYNAMIC_DRAW);
        glBindBuffer(GL_UNIFORM_BUFFER, 0);
        glBindBufferBase(GL_UNIFORM_BUFFER, _binding, _buffer);

        return bytes;
    }

    //  #endregion

    /**
     * Update the openGL state so it can draw the provided command.
     * @param _command      Command to set the state for.
     * @param _disableStats If stats are to be recorded.
     */
    function setState(_command : DrawCommand, _disableStats : Bool)
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
                glGenFramebuffers(1, fbo);
                glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureObjects.get(target.id), 0);

                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
                {
                    throw new GL32IncompleteFramebufferException(target.id);
                }

                framebufferObjects.set(target.id, fbo[0]);

                glBindFramebuffer(GL_FRAMEBUFFER, 0);
            }

            glBindFramebuffer(GL_FRAMEBUFFER, target != null ? framebufferObjects.get(target.id) : backbuffer.framebuffer);

            if (!_disableStats)
            {
                rendererStats.targetSwaps++;
            }
        }

        // Apply shader changes.
        if (shader != _command.shader)
        {
            shader = _command.shader;
            glUseProgram(shaderPrograms.get(shader.id));

            if (!_disableStats)
            {
                rendererStats.shaderSwaps++;
            }
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
            viewport.copyFrom(cmdViewport);
            
            var x = viewport.x *= target == null ? backbuffer.scale : 1;
            var y = viewport.y *= target == null ? backbuffer.scale : 1;
            var w = viewport.w *= target == null ? backbuffer.scale : 1;
            var h = viewport.h *= target == null ? backbuffer.scale : 1;

            glViewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

            if (!_disableStats)
            {
                rendererStats.viewportSwaps++;
            }
        }

        // Set the scissor region.
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

            glScissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

            if (!_disableStats)
            {
                rendererStats.scissorSwaps++;
            }
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

            if (!_disableStats)
            {
                rendererStats.blendSwaps++;
            }
        }
        else
        {
            glDisable(GL_BLEND);

            if (!_disableStats)
            {
                rendererStats.blendSwaps++;
            }
        }

        // Apply the shaders uniforms
        // TODO : Only set uniforms if the value has changed.
        setUniforms(_command, _disableStats);
    }

    /**
     * Apply all of a shaders uniforms.
     * @param _combined     Only required uniform. VP combined matrix.
     * @param _disableStats If stats are to be recorded.
     */
    function setUniforms(_command : DrawCommand, _disableStats : Bool)
    {
        // Find this shaders location cache.
        var cache = shaderUniforms.get(_command.shader.id);
        var preferedUniforms = _command.uniforms.or(_command.shader.uniforms);

        if (cache.layout.textures.length == _command.textures.length)
        {
            // then go through each texture and bind it if it isn't already.
            for (i in 0..._command.textures.length)
            {
                var glTextureID  = textureObjects.get(_command.textures[i].id);
                if (glTextureID != textureSlots[i])
                {
                    glActiveTexture(GL_TEXTURE0 + cache.textureLocations[i]);
                    glBindTexture(GL_TEXTURE_2D, glTextureID);

                    textureSlots[i] = glTextureID;

                    rendererStats.textureSwaps++;
                }
            }
        }
        else
        {
            throw new GL32NotEnoughTexturesException(_command.shader.id, _command.id, cache.layout.textures.length, _command.textures.length);
        }

        for (i in 0...cache.layout.blocks.length)
        {
            glBindBuffer(GL_UNIFORM_BUFFER, cache.blockBuffers[i]);

            var ptr = Pointer.arrayElem(cache.blockBytes[i].getData(), 0);

            if (cache.layout.blocks[i].name == 'defaultMatrices')
            {
                buildCameraMatrices(_command.camera);

                var model      = bufferModelMatrix.exists(_command.id) ? bufferModelMatrix.get(_command.id) : dummyModelMatrix;
                var view       = _command.camera.view;
                var projection = _command.camera.projection;

                memcpy(ptr          , (projection : Float32Array).view.buffer.getData().address(0), 64);
                memcpy(ptr.incBy(64), (view       : Float32Array).view.buffer.getData().address(0), 64);
                memcpy(ptr.incBy(64), (model      : Float32Array).view.buffer.getData().address(0), 64);
            }
            else
            {
                // Otherwise upload all user specified uniform values.
                // TODO : We should have some sort of error checking if the expected uniforms are not found.
                var pos = 0;
                for (val in cache.layout.blocks[i].vals)
                {
                    switch (ShaderType.createByName(val.type))
                    {
                        case Matrix4:
                            var mat = preferedUniforms.matrix4.exists(val.name) ? preferedUniforms.matrix4.get(val.name) : _command.shader.uniforms.matrix4.get(val.name);
                            memcpy(ptr.incBy(pos), (mat : Float32Array).view.buffer.getData().address(0), 64);
                            pos += 64;
                        case Vector4:
                            var vec = preferedUniforms.vector4.exists(val.name) ? preferedUniforms.vector4.get(val.name) : _command.shader.uniforms.vector4.get(val.name);
                            memcpy(ptr.incBy(pos), (vec : Float32Array).view.buffer.getData().address(0), 16);
                            pos += 16;
                        case Int:
                            var dst : Pointer<Int32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), preferedUniforms.int.exists(val.name) ? preferedUniforms.int.get(val.name) : _command.shader.uniforms.int.get(val.name));
                            pos += 4;
                        case Float:
                            var dst : Pointer<Float32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), preferedUniforms.float.exists(val.name) ? preferedUniforms.float.get(val.name) : _command.shader.uniforms.float.get(val.name));
                            pos += 4;
                    }
                }
            }
            
            glBufferSubData(GL_UNIFORM_BUFFER, 0, cache.blockBytes[i].length, cache.blockBytes[i].getData());
        }
    }

    function buildCameraMatrices(_camera : Camera)
    {
        switch _camera.type
        {
            case Orthographic:
                var orth = (cast _camera : Camera2D);
                if (orth.dirty)
                {
                    orth.projection.makeHomogeneousOrthographic(0, orth.viewport.w, orth.viewport.h, 0, -100, 100);
                    orth.view.copy(orth.transformation.transformation).invert();
                    orth.dirty = false;
                }
            case Projection:
                var proj = (cast _camera : Camera3D);
                if (proj.dirty)
                {
                    proj.projection.makeHomogeneousPerspective(proj.fov, proj.aspect, proj.near, proj.far);
                    proj.projection.scale(perspectiveYFlipVector);
                    proj.view.copy(proj.transformation.transformation).invert();
                    proj.dirty = false;
                }
            case Custom:
                // Do nothing, user is responsible for building their custom camera matrices.
        }
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
        if (target == null)
        {
            glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
        }
        else
        {
            glBindFramebuffer(GL_FRAMEBUFFER, framebufferObjects.get(target.id));
        }

        for (i in 0...textureSlots.length) textureSlots[i] = 0;

        return new BackBuffer(_width, _height, 1, tex[0], rbo[0], fbo[0]);
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
     * Location of all shader blocks.
     */
    public final blockLocations : Array<Int>;

    /**
     * SSBO buffer objects.
     */
    public final blockBuffers : Array<Int>;

    /**
     * Bytes for each SSBO buffer.
     */
    public final blockBytes : Array<Bytes>;

    public function new(_layout : ShaderLayout, _textureLocations : Array<Int>, _blockLocations : Array<Int>, _blockBuffers : Array<Int>, _blockBytes : Array<Bytes>)
    {
        layout           = _layout;
        textureLocations = _textureLocations;
        blockLocations   = _blockLocations;
        blockBuffers     = _blockBuffers;
        blockBytes       = _blockBytes;
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
    public final indexByteOffset : Int;

    inline public function new(_vertices : Int, _vertexOffset : Int, _indices : Int, _indexByteOffset)
    {
        vertices        = _vertices;
        vertexOffset    = _vertexOffset;
        indices         = _indices;
        indexByteOffset = _indexByteOffset;
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
