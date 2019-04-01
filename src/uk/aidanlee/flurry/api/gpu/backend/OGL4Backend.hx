package uk.aidanlee.flurry.api.gpu.backend;

import cpp.UInt8;
import haxe.io.Bytes;
import haxe.ds.Map;
import cpp.Float32;
import cpp.UInt16;
import cpp.Int32;
import cpp.Pointer;
import sdl.GLContext;
import sdl.Window;
import sdl.SDL;
import opengl.GL.*;
import opengl.GL.GLSync;
import opengl.WebGL;
import haxe.io.Float32Array;
import haxe.io.UInt16Array;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.Resource.ShaderType;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderBlock;
import uk.aidanlee.flurry.api.resources.ResourceEvents;

using cpp.NativeArray;

/**
 * OpenGL 4.5 renderer. Makes use of DSA, named buffers, persistent mapping, and (hopefully) eventually stuff like SSBOs and bindless textures.
 * DSA has the highest requirements as it was only made core in 4.5.
 * This renderer will not work on OSX, webGL, and older integrated GPUs.
 * 
 * WebGL class is still imported as it has some useful haxe friendly functions for shaders.
 * 
 * This renderer makes use of the following extensions
 * - ARB_direct_state_access (made core in 4.5)
 * - ARB_buffer_storage      (made core in 4.4)
 * - ARB_texture_storage     (made core in 4.2)
 */
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
     * Event bus for the rendering backend to listen to resource creation events.
     */
    final events : EventBus;

    /**
     * Access to the renderer who owns this backend.
     */
    final rendererStats : RendererStats;

    /**
     * If we will be using bindless textures.
     */
    final bindless : Bool;

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
     * Backbuffer display, default target if none is specified.
     */
    final backbuffer : BackBuffer;

    /**
     * Tracks the position and number of vertices for draw commands uploaded into the dynamic buffer.
     */
    final dynamicCommandRanges : Map<Int, DrawCommandRange>;

    /**
     * Tracks, stores, and uploads unchaning commands and its required state.
     */
    final unchangingStorage : UnchangingBuffer;

    /**
     * These ranges describe writable chunks of the vertex buffer.
     * This is used for triple buffering with mapped buffers where only one chunk can be written to at a time.
     */
    final vertexBufferRanges : Array<BufferRange>;

    /**
     * The persistently mapped float buffer to write vertex data into.
     * This will be three times the requested float size for triple buffering.
     */
    final vertexBuffer : Array<Float32>;

    /**
     * Describes a set of ranges the triple buffered dynamic index buffer.
     * Each range contains a int offset and byte offset.
     */
    final indexBufferRanges : Array<BufferRange>;

    /**
     * The persistently mapped ushort buffer to write index data into.
     * This buffer will be three times the requested size for triple buffering.
     */
    final indexBuffer : Array<UInt16>;

    /**
     * Constant vector instance which is used to transform vertices when copying into the vertex buffer.
     */
    final transformationVector : Vector;

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
     * 64bit texture handles keyed by their associated image resource IDs.
     * This will not be used if bindless is false.
     */
    final textureHandles : Map<String, haxe.Int64>;

    /**
     * Framebuffer objects keyed by their associated image resource IDs.
     * Framebuffers will only be generated when an image resource is used as a target.
     * Will be destroyed when the associated image resource is destroyed.
     */
    final framebufferObjects : Map<String, Int>;

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

    // Event listener IDs

    final evResourceCreated : Int;

    final evResourceRemoved : Int;

    final evChangeRequest : Int;

    final evSizeChanged : Int;

    // SDL Window and GL Context

    var window : Window;

    var glContext : GLContext;

    /**
     * Creates a new openGL 4.5 renderer.
     * @param _renderer           Access to the renderer which owns this backend.
     * @param _dynamicVertices    The maximum number of dynamic vertices in the buffer.
     * @param _unchangingVertices The maximum number of static vertices in the buffer.
     */
    public function new(_events : EventBus, _rendererStats : RendererStats, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        createWindow(_windowConfig);

        events           = _events;
        rendererStats    = _rendererStats;

        // Check for ARB_bindless_texture support
        bindless = SDL.GL_ExtensionSupported('GL_ARB_bindless_texutre');

        // Create and bind a singular VBO.
        // Only needs to be bound once since it is used for all drawing.

        var totalBufferVerts  = _rendererConfig.unchangingVertices + (_rendererConfig.dynamicVertices * 3);
        var totalBufferFloats = totalBufferVerts  * VERTEX_FLOAT_SIZE;
        var totalBufferBytes  = totalBufferFloats * Float32Array.BYTES_PER_ELEMENT;

        var totalBufferIndices = _rendererConfig.unchangingIndices + (_rendererConfig.dynamicIndices * 3);
        var totalIndexBytes    = totalBufferIndices * UInt16Array.BYTES_PER_ELEMENT;

        // Create two empty buffers, for the vertex and index data
        var buffers = [ 0, 0 ];
        glCreateBuffers(2, buffers);
        untyped __cpp__("glNamedBufferStorage({0}, {1}, nullptr, {2})", buffers[0], totalBufferBytes, GL_DYNAMIC_STORAGE_BIT | GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);
        untyped __cpp__("glNamedBufferStorage({0}, {1}, nullptr, {2})", buffers[1], totalIndexBytes , GL_DYNAMIC_STORAGE_BIT | GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);

        // Create the vao and bind the vbo to it.
        var vao = [ 0 ];
        glCreateVertexArrays(1, vao);
        glVertexArrayVertexBuffer(vao[0], 0, buffers[0], 0, Float32Array.BYTES_PER_ELEMENT * VERTEX_FLOAT_SIZE);

        // Enable and setup the vertex attributes for this batcher.
        glEnableVertexArrayAttrib(vao[0], 0);
        glEnableVertexArrayAttrib(vao[0], 1);
        glEnableVertexArrayAttrib(vao[0], 2);

        glVertexArrayAttribFormat(buffers[0], 0, 3, GL_FLOAT, false, Float32Array.BYTES_PER_ELEMENT * VERTEX_OFFSET_POS);
        glVertexArrayAttribFormat(buffers[0], 1, 4, GL_FLOAT, false, Float32Array.BYTES_PER_ELEMENT * VERTEX_OFFSET_COL);
        glVertexArrayAttribFormat(buffers[0], 2, 2, GL_FLOAT, false, Float32Array.BYTES_PER_ELEMENT * VERTEX_OFFSET_TEX);

        glVertexArrayAttribBinding(vao[0], 0, 0);
        glVertexArrayAttribBinding(vao[0], 1, 0);
        glVertexArrayAttribBinding(vao[0], 2, 0);

        glVbo = buffers[0];
        glIbo = buffers[1];
        glVao = vao[0];

        // Bind our VAO once.
        glBindVertexArray(glVao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIbo);

        // Define the dynamic vertex triple buffering ranges
        // These ranges will map into the array pointer.
        // Offset to ignore the unchanging region.

        var floatSegmentSize = _rendererConfig.dynamicVertices    * VERTEX_FLOAT_SIZE;
        var floatOffsetSize  = _rendererConfig.unchangingVertices * VERTEX_FLOAT_SIZE;

        vertexBufferRangeIndex = 0;
        vertexBufferRanges = [
            new BufferRange(floatOffsetSize                         , _rendererConfig.unchangingVertices),
            new BufferRange(floatOffsetSize + floatSegmentSize      , _rendererConfig.unchangingVertices +  _rendererConfig.dynamicVertices),
            new BufferRange(floatOffsetSize + (floatSegmentSize * 2), _rendererConfig.unchangingVertices + (_rendererConfig.dynamicVertices * 2))
        ];

        var shortSegmentSize = _rendererConfig.dynamicIndices    * UInt16Array.BYTES_PER_ELEMENT;
        var shortOffsetSize  = _rendererConfig.unchangingIndices * UInt16Array.BYTES_PER_ELEMENT;

        indexBufferRangeIndex = 0;
        indexBufferRanges = [
            new BufferRange(shortOffsetSize                         , _rendererConfig.unchangingIndices),
            new BufferRange(shortOffsetSize +  shortSegmentSize     , _rendererConfig.unchangingIndices +  _rendererConfig.dynamicIndices),
            new BufferRange(shortOffsetSize + (shortSegmentSize * 2), _rendererConfig.unchangingIndices + (_rendererConfig.dynamicIndices * 2))
        ];

        // create a new storage container for holding unchaning commands.
        unchangingStorage    = new UnchangingBuffer(_rendererConfig.unchangingVertices, _rendererConfig.unchangingIndices);
        dynamicCommandRanges = new Map();
        transformationVector = new Vector();

        // Map the buffer into an unmanaged array.
        var ptr : Pointer<Float32> = Pointer.fromRaw(glMapNamedBufferRange(glVbo, 0, totalBufferBytes, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT)).reinterpret();
        vertexBuffer = ptr.toUnmanagedArray(totalBufferFloats);

        var ptr : Pointer<UInt16> = Pointer.fromRaw(glMapNamedBufferRange(glIbo, 0, totalIndexBytes, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT)).reinterpret();
        indexBuffer = ptr.toUnmanagedArray(totalBufferIndices);

        // Create a representation of the backbuffer and manually insert it into the target structure.
        var backbufferID = [ 0 ];
        glGetIntegerv(GL_FRAMEBUFFER, backbufferID);

        backbuffer = new BackBuffer(_windowConfig.width, _windowConfig.height, 1, backbufferID[0]);

        // Default blend mode
        // TODO : Move this to be a settable property in the geometry or renderer or something
        glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);

        // Set the clear colour
        glClearColor(_rendererConfig.clearColour.r, _rendererConfig.clearColour.g, _rendererConfig.clearColour.b, _rendererConfig.clearColour.a);

        // Default scissor test
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        // default state
        viewport = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        clip     = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        target   = null;
        shader   = null;

        shaderPrograms = new Map();
        shaderUniforms = new Map();

        textureObjects = new Map();
        textureHandles = new Map();

        framebufferObjects = new Map();

        // Listen to resource creation events.
        evResourceCreated = events.listen(ResourceEvents.Created       , onResourceCreated);
        evResourceRemoved = events.listen(ResourceEvents.Removed       , onResourceRemoved);
        evChangeRequest   = events.listen(DisplayEvents.ChangeRequested, onChangeRequest);
        evSizeChanged     = events.listen(DisplayEvents.SizeChanged    , onSizeChanged);
    }

    /**
     * Clears the display with the colour bit.
     */
    public function clear()
    {
        // Disable the clip to clear the entire target.
        clip.set(0, 0, backbuffer.width, backbuffer.height);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        glClear(GL_COLOR_BUFFER_BIT);
    }

    /**
     * Clears all unchanging sub range definitions.
     */
    public function clearUnchanging()
    {
        unchangingStorage.empty();
    }

    /**
     * Unlock the range we will be writing into and set the offsets to that of the range.
     */
    public function preDraw()
    {
        unlockBuffer(vertexBufferRanges[vertexBufferRangeIndex]);
        unlockBuffer(indexBufferRanges[indexBufferRangeIndex]);

        vertexFloatOffset = vertexBufferRanges[vertexBufferRangeIndex].typeOffset;
        vertexOffset      = vertexBufferRanges[vertexBufferRangeIndex].offset;

        indexByteOffset   = indexBufferRanges[indexBufferRangeIndex].typeOffset;
        indexOffset       = indexBufferRanges[indexBufferRangeIndex].offset;
    }

    /**
     * Upload a series of geometry commands into the current buffer range.
     * @param _commands Commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>)
    {
        for (command in _commands)
        {
            if (command.unchanging)
            {
                var unchangingVertexOffset = unchangingStorage.currentVertices;
                var unchangingFloatOffset  = unchangingStorage.currentVertices * VERTEX_FLOAT_SIZE;
                var unchangingIndexOffset  = unchangingStorage.currentIndices;

                if (unchangingStorage.exists(command.id))
                {
                    continue;
                }

                if (unchangingStorage.add(command))
                {
                    for (geom in command.geometry)
                    {
                        var matrix = geom.transformation.transformation;

                        for (index in geom.indices)
                        {
                            indexBuffer[unchangingIndexOffset++] = unchangingVertexOffset + index;
                        }

                        for (vertex in geom.vertices)
                        {
                            // Copy the vertex into another vertex.
                            // This allows us to apply the transformation without permanently modifying the original geometry.
                            transformationVector.copyFrom(vertex.position);
                            transformationVector.transform(matrix);

                            vertexBuffer[unchangingFloatOffset++] = transformationVector.x;
                            vertexBuffer[unchangingFloatOffset++] = transformationVector.y;
                            vertexBuffer[unchangingFloatOffset++] = transformationVector.z;
                            vertexBuffer[unchangingFloatOffset++] = vertex.color.r;
                            vertexBuffer[unchangingFloatOffset++] = vertex.color.g;
                            vertexBuffer[unchangingFloatOffset++] = vertex.color.b;
                            vertexBuffer[unchangingFloatOffset++] = vertex.color.a;
                            vertexBuffer[unchangingFloatOffset++] = vertex.texCoord.x;
                            vertexBuffer[unchangingFloatOffset++] = vertex.texCoord.y;
                        }
                    }

                    continue;
                }
            }

            var rangeIndexOffset = 0;

            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, command.indices, indexByteOffset));

            for (geom in command.geometry)
            {
                var matrix = geom.transformation.transformation;

                for (index in geom.indices)
                {
                    indexBuffer[indexOffset++] = rangeIndexOffset + index;
                }

                for (vertex in geom.vertices)
                {
                    // Copy the vertex into another vertex.
                    // This allows us to apply the transformation without permanently modifying the original geometry.
                    transformationVector.copyFrom(vertex.position);
                    transformationVector.transform(matrix);

                    vertexBuffer[vertexFloatOffset++] = transformationVector.x;
                    vertexBuffer[vertexFloatOffset++] = transformationVector.y;
                    vertexBuffer[vertexFloatOffset++] = transformationVector.z;
                    vertexBuffer[vertexFloatOffset++] = vertex.color.r;
                    vertexBuffer[vertexFloatOffset++] = vertex.color.g;
                    vertexBuffer[vertexFloatOffset++] = vertex.color.b;
                    vertexBuffer[vertexFloatOffset++] = vertex.color.a;
                    vertexBuffer[vertexFloatOffset++] = vertex.texCoord.x;
                    vertexBuffer[vertexFloatOffset++] = vertex.texCoord.y;
                }

                indexByteOffset  += geom.indices.length * UInt16Array.BYTES_PER_ELEMENT;
                vertexOffset     += geom.vertices.length;
                rangeIndexOffset += geom.vertices.length;
            }
        }
    }

    /**
     * Upload a series of buffer commands into the current buffer range.
     * @param _commands Buffer commands.
     */
    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>)
    {
        for (command in _commands)
        {
            if (command.unchanging)
            {
                var unchangingOffset = unchangingStorage.currentVertices * VERTEX_FLOAT_SIZE;

                if (unchangingStorage.exists(command.id))
                {
                    continue;
                }

                if (unchangingStorage.add(command))
                {
                    for (i in command.startIndex...command.endIndex)
                    {
                        vertexBuffer[unchangingOffset++] = command.buffer[i];
                    }

                    continue;
                }
            }

            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, 0, 0));

            for (i in command.startIndex...command.endIndex)
            {
                vertexBuffer[vertexFloatOffset++] = command.buffer[i];
            }

            vertexOffset += command.vertices;
        }
    }

    /**
     * Submit a series of uploaded commands to be drawn.
     * @param _commands    Commands to draw.
     * @param _recordStats If stats are to be recorded.
     */
    public function submitCommands(_commands : Array<DrawCommand>, _recordStats : Bool = true)
    {
        for (command in _commands)
        {
            if (command.unchanging)
            {
                if (unchangingStorage.exists(command.id))
                {
                    var range = unchangingStorage.get(command.id);

                    setState(command, !_recordStats);

                    // Draw the actual vertices
                    if (command.indices > 0)
                    {
                        switch (command.primitive)
                        {
                            case Points        : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_POINTS        , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                            case Lines         : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_LINES         , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                            case LineStrip     : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_LINE_STRIP    , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                            case Triangles     : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_TRIANGLES     , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                            case TriangleStrip : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_TRIANGLE_STRIP, command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                        }
                    }
                    else
                    {
                        switch (command.primitive)
                        {
                            case Points        : glDrawArrays(GL_POINTS        , range.vertexOffset, command.vertices);
                            case Lines         : glDrawArrays(GL_LINES         , range.vertexOffset, command.vertices);
                            case LineStrip     : glDrawArrays(GL_LINE_STRIP    , range.vertexOffset, command.vertices);
                            case Triangles     : glDrawArrays(GL_TRIANGLES     , range.vertexOffset, command.vertices);
                            case TriangleStrip : glDrawArrays(GL_TRIANGLE_STRIP, range.vertexOffset, command.vertices);
                        }
                    }

                    // Record stats about this draw call.
                    if (_recordStats)
                    {
                        rendererStats.dynamicDraws++;
                        rendererStats.totalVertices += command.vertices;
                    }

                    continue;
                }
            }

            var range = dynamicCommandRanges.get(command.id);

            // Change the state so the vertices are drawn correctly.
            setState(command, !_recordStats);

            // Draw the actual vertices
            if (command.indices > 0)
            {
                switch (command.primitive)
                {
                    case Points        : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_POINTS        , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                    case Lines         : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_LINES         , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                    case LineStrip     : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_LINE_STRIP    , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                    case Triangles     : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_TRIANGLES     , command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                    case TriangleStrip : untyped __cpp__('glDrawElementsBaseVertex({0}, {1}, {2}, (void*)(intptr_t){3}, {4})', GL_TRIANGLE_STRIP, command.indices, GL_UNSIGNED_SHORT, range.indexByteOffset, range.vertexOffset);
                }
            }
            else
            {
                switch (command.primitive)
                {
                    case Points        : glDrawArrays(GL_POINTS        , range.vertexOffset, command.vertices);
                    case Lines         : glDrawArrays(GL_LINES         , range.vertexOffset, command.vertices);
                    case LineStrip     : glDrawArrays(GL_LINE_STRIP    , range.vertexOffset, command.vertices);
                    case Triangles     : glDrawArrays(GL_TRIANGLES     , range.vertexOffset, command.vertices);
                    case TriangleStrip : glDrawArrays(GL_TRIANGLE_STRIP, range.vertexOffset, command.vertices);
                }
            }

            // Record stats about this draw call.
            if (_recordStats)
            {
                rendererStats.dynamicDraws++;
                rendererStats.totalVertices += range.vertices;
            }
        }
    }

    /**
     * Locks the range we are currenly writing to and increments the index.
     */
    public function postDraw()
    {
        lockBuffer(vertexBufferRanges[vertexBufferRangeIndex]);
        lockBuffer(indexBufferRanges[indexBufferRangeIndex]);

        vertexBufferRangeIndex = (vertexBufferRangeIndex + 1) % 3;
        indexBufferRangeIndex  = (indexBufferRangeIndex + 1) % 3;

        SDL.GL_SwapWindow(window);
    }

    /**
     * Unmap the buffer and iterate over all resources deleting their resources and remove them from the structure.
     */
    public function cleanup()
    {
        glUnmapNamedBuffer(glVbo);

        for (shaderID in shaderPrograms.keys())
        {
            glDeleteProgram(shaderPrograms.get(shaderID));

            shaderPrograms.remove(shaderID);
            shaderUniforms.remove(shaderID);
        }

        for (textureID in textureObjects.keys())
        {
            if (bindless)
            {
                glMakeTextureHandleNonResidentARB(cast textureHandles.get(textureID));
                textureHandles.remove(textureID);
            }

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
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 5);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        window    = SDL.createWindow('Flurry', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _options.width, _options.height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
        glContext = SDL.GL_CreateContext(window);

        SDL.GL_MakeCurrent(window, glContext);

        // TODO : Error handling if GLEW doesn't return OK.
        glew.GLEW.init();
    }

    function onChangeRequest(_event : DisplayEventChangeRequest)
    {
        SDL.setWindowSize(window, _event.width, _event.height);
        SDL.setWindowFullscreen(window, _event.fullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
        SDL.GL_SetSwapInterval(_event.vsync ? 1 : 0);
    }

    function onSizeChanged(_event : DisplayEventData)
    {
        backbuffer.width  = _event.width;
        backbuffer.height = _event.height;
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

        // Create vertex shader.
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        WebGL.shaderSource(vertex, _resource.ogl4.vertex);
        glCompileShader(vertex);

        if (WebGL.getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw 'OpenGL 4.5 Backend Exception : ${_resource.id} : Error compiling vertex shader : ${WebGL.getShaderInfoLog(vertex)}';
        }

        // Create fragment shader.
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        WebGL.shaderSource(fragment, _resource.ogl4.fragment);
        glCompileShader(fragment);

        if (WebGL.getShaderParameter(fragment, GL_COMPILE_STATUS) == 0)
        {
            throw 'OpenGL 4.5 Backend Exception : ${_resource.id} : Error compiling fragment shader : ${WebGL.getShaderInfoLog(fragment)}';
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
        var blockBindings    = [ for (i in 0..._resource.layout.blocks.length) i ];

        for (i in 0..._resource.layout.blocks.length)
        {
            glShaderStorageBlockBinding(program, blockLocations[i], blockBindings[i]);
        }

        var blockBuffers = [ for (i in 0..._resource.layout.blocks.length) 0 ];
        glCreateBuffers(blockBuffers.length, blockBuffers);
        var blockBytes = [ for (i in 0..._resource.layout.blocks.length) generateUniformBlock(_resource.layout.blocks[i], blockBuffers[i], blockBindings[i]) ];

        glBindBuffersBase(GL_SHADER_STORAGE_BUFFER, blockBindings[0], blockBindings.length, blockBuffers);

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderLocations(_resource.layout, textureLocations, blockLocations, blockBuffers, blockBytes));
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
        glTextureSubImage2D(ids[0], 0, 0, 0, _resource.width, _resource.height, GL_BGRA, GL_UNSIGNED_BYTE, _resource.pixels);

        textureObjects.set(_resource.id, ids[0]);

        if (bindless)
        {
            var handle = glGetTextureHandleARB(ids[0]);
            glMakeTextureHandleResidentARB(handle);

            textureHandles.set(_resource.id, handle);
        }
    }

    /**
     * Free the GPU resources used by a texture.
     * @param _resource Image resource to remove.
     */
    function removeTexture(_resource : ImageResource)
    {
        if (bindless)
        {
            glMakeTextureHandleNonResidentARB(cast textureHandles.get(_resource.id));
            textureHandles.remove(_resource.id);
        }

        glDeleteTextures(1, [ textureObjects.get(_resource.id) ]);
        textureObjects.remove(_resource.id);
    }

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
        glNamedBufferData(_buffer, bytes.length, bytes.getData(), GL_DYNAMIC_DRAW);
        //glBindBufferBase(GL_SHADER_STORAGE_BUFFER, _binding, _buffer);
        
        return bytes;
    }

    // #endregion

    // #region State Management

    /**
     * Update the openGL state so it can draw the provided command.
     * @param _command      Command to set the state for.
     * @param _disableStats If stats are to be recorded.
     */
    function setState(_command : DrawCommand, _disableStats : Bool)
    {
        // Set the viewport.
        // If the viewport of the command is null then the backbuffer size is used (size of the window).
        var cmdViewport = _command.viewport != null ? _command.viewport : new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        if (!viewport.equals(cmdViewport))
        {
            viewport.set(cmdViewport.x, cmdViewport.y, cmdViewport.w, cmdViewport.h);

            var x = viewport.x *= target == null ? backbuffer.viewportScale : 1;
            var y = viewport.y *= target == null ? backbuffer.viewportScale : 1;
            var w = viewport.w *= target == null ? backbuffer.viewportScale : 1;
            var h = viewport.h *= target == null ? backbuffer.viewportScale : 1;

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            y = (target == null ? backbuffer.height : target.height) - (y + h);
            glViewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

            if (!_disableStats)
            {
                rendererStats.viewportSwaps++;
            }
        }

        // Apply the scissor clip.
        if (!_command.clip.equals(clip))
        {
            clip.copyFrom(_command.clip);

            var x = clip.x * (target == null ? backbuffer.viewportScale : 1);
            var y = clip.y * (target == null ? backbuffer.viewportScale : 1);
            var w = clip.w * (target == null ? backbuffer.viewportScale : 1);
            var h = clip.h * (target == null ? backbuffer.viewportScale : 1);

            // If the clip rectangle has an area of 0 then set the width and height to that of the viewport
            // This essentially disables clipping by clipping the entire backbuffer size.
            if (clip.area() == 0)
            {
                w = backbuffer.width  * (target == null ? backbuffer.viewportScale : 1);
                h = backbuffer.height * (target == null ? backbuffer.viewportScale : 1);
            }

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            y = (target == null ? backbuffer.height : target.height) - (y + h);
            glScissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

            if (!_disableStats)
            {
                rendererStats.scissorSwaps++;
            }
        }

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

            glBindFramebuffer(GL_FRAMEBUFFER, target != null ? framebufferObjects.get(target.id) : backbuffer.framebufferObject);

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
        
        // Update shader blocks and bind any textures required.
        setUniforms(_command, _disableStats);

        // Set the blending
        if (_command.blending)
        {
            glEnable(GL_BLEND);
            glBlendFuncSeparate(getBlendMode(_command.srcRGB), getBlendMode(_command.dstRGB), getBlendMode(_command.srcAlpha), getBlendMode(_command.dstAlpha));

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
    }

    /**
     * Apply all of a shaders uniforms.
     * @param _command      Command to set the state for.
     * @param _disableStats If stats are to be recorded.
     */
    function setUniforms(_command : DrawCommand, _disableStats : Bool)
    {
        var cache = shaderUniforms.get(_command.shader.id);

        // TEMP : Set all textures all the time.
        // TODO : Store all bound texture IDs and check before binding textures.

        if (cache.layout.textures.length > _command.textures.length)
        {
            throw 'OpenGL 4.5 Backend Exception : ${_command.shader.id} : More textures required by the shader than are provided by the draw command';
        }
        else
        {
            if (bindless)
            {
                var handlesToBind : Array<cpp.UInt64> = [ for (texture in _command.textures) cast textureHandles.get(texture.id) ];
                glUniformHandleui64vARB(0, handlesToBind.length, handlesToBind);
            }
            else
            {
                // then go through each texture and bind it if it isn't already.
                var texturesToBind : Array<Int> = [ for (texture in _command.textures) textureObjects.get(texture.id) ];
                glBindTextures(0, texturesToBind.length, texturesToBind);

                if (!_disableStats)
                {
                    rendererStats.textureSwaps++;
                }
            }
        }
        
        for (i in 0...cache.layout.blocks.length)
        {
            var ptr : Pointer<UInt8> = Pointer.fromRaw(glMapNamedBuffer(cache.blockBuffers[i], GL_WRITE_ONLY)).reinterpret();

            if (cache.layout.blocks[i].name == 'defaultMatrices')
            {
                cpp.Stdlib.memcpy(ptr          , (_command.projection : Float32Array).view.buffer.getData().address(0), 64);
                cpp.Stdlib.memcpy(ptr.incBy(64), (_command.view       : Float32Array).view.buffer.getData().address(0), 64);
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
                            cpp.Stdlib.memcpy(ptr.incBy(pos), (_command.shader.uniforms.matrix4.get(val.name) : Float32Array).view.buffer.getData().address(0), 64);
                            pos += 64;
                        case Vector4:
                            cpp.Stdlib.memcpy(ptr.incBy(pos), (_command.shader.uniforms.vector4.get(val.name) : Float32Array).view.buffer.getData().address(0), 16);
                            pos += 16;
                        case Int:
                            var dst : Pointer<Int32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), _command.shader.uniforms.int.get(val.name));
                            pos += 4;
                        case Float:
                            var dst : Pointer<Float32> = ptr.reinterpret();
                            dst.setAt(Std.int(pos / 4), _command.shader.uniforms.float.get(val.name));
                            pos += 4;
                    }
                }
            }

            glUnmapNamedBuffer(cache.blockBuffers[i]);
            // if (cache.layout.blocks[i].name == 'defaultMatrices')
            // {
            //     var pos = 0;
            //     for (el in cast (_command.projection, Float32Array))
            //     {
            //         cache.blockBytes[0].setFloat(pos, el);
            //         pos += 4;
            //     }
            //     for (el in cast (_command.view, Float32Array))
            //     {
            //         cache.blockBytes[0].setFloat(pos, el);
            //         pos += 4;
            //     }
            // }
            // else
            // {
            //     var bytePosition = 0;
            //     for (val in cache.layout.blocks[i].vals)
            //     {
            //         switch (ShaderType.createByName(val.type))
            //         {
            //             case Matrix4: bytePosition += writeMatrix4(cache.blockBytes[i], bytePosition, _command.shader.uniforms.matrix4.get(val.name));
            //             case Vector4: bytePosition += writeVector4(cache.blockBytes[i], bytePosition, _command.shader.uniforms.vector4.get(val.name));
            //             case Int    : bytePosition += writeInt(cache.blockBytes[i], bytePosition, _command.shader.uniforms.int.get(val.name));
            //             case Float  : bytePosition += writeFloat(cache.blockBytes[i], bytePosition, _command.shader.uniforms.float.get(val.name));
            //         }
            //     }
            // }

            // glNamedBufferSubData(cache.blockBuffers[i], 0, cache.blockBytes[i].length, cache.blockBytes[i].getData());
        }
    }

    /**
     * Returns the equivalent openGL blend mode from the abstract blend enum
     * @param _mode Blend mode to fetch.
     * @return Int
     */
    function getBlendMode(_mode : BlendMode) : Int
    {
        return switch (_mode)
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

    /**
     * Locks a buffer range from writing placing an openGL fence on it.
     * @param _range Buffer range to lock.
     */
    function lockBuffer(_range : BufferRange)
    {
        if (_range.sync != null)
        {
            glDeleteSync(_range.sync);
        }

        _range.sync = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    }

    /**
     * Unlocks the buffer range by waiting until its ready.
     * This will lock the client thread.
     * @param _range Buffer range to unlock.
     */
    function unlockBuffer(_range : BufferRange)
    {
        if (_range.sync != null)
        {
            while (true)
            {
                var waitReturn = glClientWaitSync(_range.sync, GL_SYNC_FLUSH_COMMANDS_BIT, 1000);
                if (waitReturn == GL_ALREADY_SIGNALED || waitReturn == GL_CONDITION_SATISFIED)
                {
                    break;
                }
            }
        }
    }

    // #endregion
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
    public var framebufferObject : Int;

    public function new(_width : Int, _height : Int, _viewportScale : Float, _framebuffer : Int)
    {
        width             = _width;
        height            = _height;
        viewportScale     = _viewportScale;
        framebufferObject = _framebuffer;
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
 * Describes a range of a buffer by holding the float and vertex offset for the beginning of the buffer.
 */
private class BufferRange
{
    /**
     * Float offset of this buffer range.
     */
    public final typeOffset : Int;

    /**
     * Vertex offset of this buffer range.
     */
    public final offset : Int;

    /**
     * OpenGL sync object used to lock this buffer range.
     */
    public var sync : GLSync;

    public function new(_typeOffset : Int, _offset : Int)
    {
        typeOffset = _typeOffset;
        offset     = _offset;
    }
}

/**
 * Manages all of the unchanging batches currently stored.
 */
private class UnchangingBuffer
{
    /**
     * The total number of vertices we can store.
     */
    final maxVertices : Int;

    /**
     * The total number of indices we can store.
     */
    final maxIndices : Int;

    /**
     * Maps a draw commands hash to the vertex offset of that commands vertices in the unchanging buffer range.
     */
    final currentRanges : Map<Int, UnchangingRange>;

    /**
     * The current number of vertices we have stored.
     */
    public var currentVertices (default, null) : Int;

    /**
     * The current number of indices we have stored.
     */
    public var currentIndices (default, null) : Int;

    public function new(_maxVertices : Int, _maxIndices : Int)
    {
        maxVertices     = _maxVertices;
        maxIndices      = _maxIndices;
        currentVertices = 0;
        currentIndices  = 0;
        currentRanges   = new Map();
    }

    /**
     * Attempts to add a draw command into the unchanging range.
     * @param _command The command to add.
     * @return Bool if the command was successfully added.
     */
    public function add(_command : DrawCommand) : Bool
    {
        if ((currentVertices + _command.vertices) <= maxVertices && (currentIndices + _command.indices) <= maxIndices)
        {
            currentRanges.set(_command.id, new UnchangingRange(currentVertices, currentIndices * UInt16Array.BYTES_PER_ELEMENT));
            currentVertices += _command.vertices;
            currentIndices  += _command.indices;

            return true;
        }

        return false;
    }

    /**
     * Returns if a unchanging sub range with the specified draw command hash exists.
     * @param _id Draw command hash.
     * @return Bool
     */
    public function exists(_id : Int) : Bool
    {
        return currentRanges.exists(_id);
    }

    /**
     * Returns the unchanging sub range with the specified draw command hash.
     * @param _id Draw command hash.
     * @return Vertex offset into the unchanging range.
     */
    public function get(_id : Int) : UnchangingRange
    {
        return currentRanges.get(_id);
    }

    /**
     * Removes all sub range definitions allowing new sub range data to be stored.
     */
    public function empty()
    {
        for (key in currentRanges.keys())
        {
            currentRanges.remove(key);
        }
    }
}

private class UnchangingRange
{
    public final vertexOffset : Int;

    public final indexByteOffset : Int;

    public function new(_vertexOffset : Int, _indexByteOffset : Int)
    {
        vertexOffset    = _vertexOffset;
        indexByteOffset = _indexByteOffset;
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

    inline public function new(_vertices : Int, _vertexOffset : Int, _indices : Int, _indexByteOffset : Int)
    {
        vertices        = _vertices;
        vertexOffset    = _vertexOffset;
        indices         = _indices;
        indexByteOffset = _indexByteOffset;
    }
}
