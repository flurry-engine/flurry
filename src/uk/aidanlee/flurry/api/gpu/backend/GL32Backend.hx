package uk.aidanlee.flurry.api.gpu.backend;

import haxe.Exception;
import haxe.io.UInt8Array;
import haxe.io.Float32Array;
import haxe.io.UInt16Array;
import cpp.UInt16;
import cpp.Float32;
import cpp.Pointer;
import opengl.GL.*;
import opengl.WebGL.getShaderParameter;
import opengl.WebGL.shaderSource;
import opengl.WebGL.getProgramParameter;
import opengl.WebGL.getProgramInfoLog;
import opengl.WebGL.getShaderInfoLog;
import opengl.WebGL.uniformMatrix4fv;
import opengl.WebGL.uniform4fv;
import opengl.WebGL.uniform1f;
import sdl.Window;
import sdl.GLContext;
import sdl.SDL;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.flurry.api.gpu.geometry.Blending.BlendMode;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.Resource.ShaderType;
import uk.aidanlee.flurry.api.resources.Resource.ShaderLayout;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;

/**
 * WebGL backend written against the webGL 1.0 spec (openGL ES 2.0).
 * Uses snows openGL module so it can run on desktops and web platforms.
 * Allows targeting web, osx, and older integrated GPUs (anywhere where openGL 4.5 isn't supported).
 */
class GL32Backend implements IRendererBackend
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
     * Backbuffer display, default target if none is specified.
     */
    final backbuffer : BackBuffer;

    /**
     * Transformation vector used for transforming geometry vertices by a matrix.
     */
    final transformationVector : Vector;

    /**
     * Tracks the position and number of vertices for draw commands uploaded into the dynamic buffer.
     */
    final dynamicCommandRanges : Map<Int, DrawCommandRange>;

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
     * The number of vertices that have been written into the vertex buffer this frame.
     */
    var vertexOffset : Int;

    /**
     * The number of 32bit floats that have been written into the vertex buffer this frame.
     */
    var vertexFloatOffset : Int;

    /**
     * The number of bytes that have been written into the vertex buffer this frame.
     */
    var vertexByteOffset : Int;

    /**
     * The number of indices that have been written into the index buffer this frame.
     */
    var indexOffset : Int;

    /**
     * The number of bytes that have been written into the index buffer this frame.
     */
    var indexByteOffset : Int;

    // GL state variables

    var target   : ImageResource;
    var shader   : ShaderResource;
    var clip     : Rectangle;
    var viewport : Rectangle;
    var boundTextures : Array<Int>;

    // Event listener IDs

    final evResourceCreated : Int;

    final evResourceRemoved : Int;

    final evChangeRequest : Int;

    final evSizeChanged : Int;

    // SDL Window and GL Context

    var window : Window;

    var glContext : GLContext;

    public function new(_events : EventBus, _rendererStats : RendererStats, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererConfig)
    {
        events        = _events;
        rendererStats = _rendererStats;

        createWindow(_windowConfig);

        shaderPrograms     = [];
        shaderUniforms     = [];
        textureObjects     = [];
        framebufferObjects = [];

        transformationVector = new Vector();
        dynamicCommandRanges = [];

        vertexOffset      = 0;
        vertexFloatOffset = 0;
        vertexByteOffset  = 0;

        indexOffset     = 0;
        indexByteOffset = 0;

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

        // Create a representation of the backbuffer.
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
        shader   = null;
        target   = null;
        boundTextures = [];

        // Listen to resource creation events.
        evResourceCreated = events.listen(ResourceEvents.Created       , onResourceCreated);
        evResourceRemoved = events.listen(ResourceEvents.Removed       , onResourceRemoved);
        evChangeRequest   = events.listen(DisplayEvents.ChangeRequested, onChangeRequest);
        evSizeChanged     = events.listen(DisplayEvents.SizeChanged    , onSizeChanged);
    }

    /**
     * Clear the render target.
     */
    public function clear()
    {
        // Disable the clip to clear the entire target.
        clip.set(0, 0, backbuffer.width, backbuffer.height);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        glClear(GL_COLOR_BUFFER_BIT);
    }

    public function clearUnchanging()
    {
        //
    }

    public function preDraw()
    {
        vertexOffset      = 0;
        vertexFloatOffset = 0;
        vertexByteOffset  = 0;

        indexOffset     = 0;
        indexByteOffset = 0;
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
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, command.indices, indexByteOffset));

            var rangeIndexOffset = 0;
            for (geom in command.geometry)
            {
                var matrix = geom.transformation.transformation;

                for (index in geom.indices)
                {
                    idxDst[indexOffset++] = rangeIndexOffset + index;
                }

                for (vertex in geom.vertices)
                {
                    // Copy the vertex into another vertex.
                    // This allows us to apply the transformation without permanently modifying the original geometry.
                    transformationVector.copyFrom(vertex.position);
                    transformationVector.transform(matrix);

                    vtxDst[vertexFloatOffset++] = transformationVector.x;
                    vtxDst[vertexFloatOffset++] = transformationVector.y;
                    vtxDst[vertexFloatOffset++] = transformationVector.z;
                    vtxDst[vertexFloatOffset++] = vertex.color.r;
                    vtxDst[vertexFloatOffset++] = vertex.color.g;
                    vtxDst[vertexFloatOffset++] = vertex.color.b;
                    vtxDst[vertexFloatOffset++] = vertex.color.a;
                    vtxDst[vertexFloatOffset++] = vertex.texCoord.x;
                    vtxDst[vertexFloatOffset++] = vertex.texCoord.y;
                }

                vertexOffset     += geom.vertices.length;
                vertexByteOffset += (VERTEX_FLOAT_SIZE * Float32Array.BYTES_PER_ELEMENT) * geom.vertices.length;
                indexByteOffset  += UInt16Array.BYTES_PER_ELEMENT * geom.indices.length;
                rangeIndexOffset += geom.vertices.length;
            }
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
        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset, 0, 0));

            var vtxDst : Pointer<Float32> = Pointer.fromRaw(glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY)).reinterpret();
            for (i in command.startIndex...command.endIndex)
            {
                vtxDst[vertexFloatOffset++] = command.buffer[i];
            }

            vertexOffset      += command.vertices;
            vertexByteOffset  += command.vertices * (VERTEX_FLOAT_SIZE * Float32Array.BYTES_PER_ELEMENT);

            glUnmapBuffer(GL_ARRAY_BUFFER);
        }
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

            // Change the state so the vertices are drawn correctly.
            setState(command, !_recordStats);

            // Draw the actual vertices
            if (range.indices > 0)
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
                    case Points        : glDrawArrays(GL_POINTS        , range.vertexOffset, range.vertices);
                    case Lines         : glDrawArrays(GL_LINES         , range.vertexOffset, range.vertices);
                    case LineStrip     : glDrawArrays(GL_LINE_STRIP    , range.vertexOffset, range.vertices);
                    case Triangles     : glDrawArrays(GL_TRIANGLES     , range.vertexOffset, range.vertices);
                    case TriangleStrip : glDrawArrays(GL_TRIANGLE_STRIP, range.vertexOffset, range.vertices);
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

    public function postDraw()
    {
        SDL.GL_SwapWindow(window);
    }

    /**
     * Unmap the buffer and iterate over all resources deleting their resources and remove them from the structure.
     */
    public function cleanup()
    {
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
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
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

        if (_resource.webgl == null)
        {
            throw new GL32NoShaderSourceException(_resource.id);
        }

        // Create vertex shader.
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        shaderSource(vertex, _resource.webgl.vertex);
        glCompileShader(vertex);

        if (getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw new GL32VertexCompilationError(_resource.id, getShaderInfoLog(vertex));
        }

        // Create fragment shader.
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        shaderSource(fragment, _resource.webgl.fragment);
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

        // WebGL has no uniform blocks so all inner values are converted to uniforms
        var textureLocations = [];
        var uniformLocations = [ glGetUniformLocation(program, 'projection'), glGetUniformLocation(program, 'view') ];
        for (texture in _resource.layout.textures)
        {
            textureLocations.push(glGetUniformLocation(program, texture));
        }
        for (block in _resource.layout.blocks)
        {
            for (uniform in block.vals)
            {
                uniformLocations.push(glGetUniformLocation(program, uniform.name));
            }
        }

        shaderPrograms.set(_resource.id, program);
        shaderUniforms.set(_resource.id, new ShaderLocations(_resource.layout, textureLocations, uniformLocations));
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
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _resource.width, _resource.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, UInt8Array.fromArray(cast _resource.pixels).getData().bytes.getData());

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

    //  #endregion

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
                glBindFramebuffer(GL_FRAMEBUFFER, fbo[0]);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureObjects.get(target.id), 0);

                if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
                {
                    throw new GL32IncompleteFramebufferException(target.id);
                }

                framebufferObjects.set(target.id, fbo[0]);

                glBindFramebuffer(GL_FRAMEBUFFER, 0);
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
        
        // Apply the shaders uniforms
        // TODO : Only set uniforms if the value has changed.
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
     * @param _combined     Only required uniform. VP combined matrix.
     * @param _disableStats If stats are to be recorded.
     */
    function setUniforms(_command : DrawCommand, _disableStats : Bool)
    {
        // Find this shaders location cache.
        var cache = shaderUniforms.get(_command.shader.id);

        // TEMP : Set all textures all the time.
        // TODO : Store all bound texture IDs and check before binding textures.
        if (cache.layout.textures.length > _command.textures.length)
        {
            throw new GL32NotEnoughTexturesException(_command.shader.id, _command.id, cache.layout.textures.length, _command.textures.length);
        }
        else
        {
            // First resize the bound texture arrays to the draw commands texture ammount
            if (boundTextures.length != _command.textures.length)
            {
                boundTextures.resize(_command.textures.length);
            }

            // then go through each texture and bind it if it isn't already.
            for (i in 0...boundTextures.length)
            {
                var glTextureID  = textureObjects.get(_command.textures[i].id);
                if (glTextureID != boundTextures[i])
                {
                    glActiveTexture(GL_TEXTURE0 + i);
                    glBindTexture(GL_TEXTURE_2D, textureObjects.get(_command.textures[i].id));

                    glUniform1i(cache.textureLocations[i], i);

                    boundTextures[i] = glTextureID;

                    if (!_disableStats)
                    {
                        rendererStats.textureSwaps++;
                    }
                }
            }
        }

        // Write the default matrix uniforms
        uniformMatrix4fv(cache.uniformLocations[0], false, _command.projection);
        uniformMatrix4fv(cache.uniformLocations[1], false, _command.view);

        // Start at uniform index 2 since the first two are the default matrix uniforms.
        var uniformIdx = 2;
        for (i in 0...cache.layout.blocks.length)
        {
            for (val in cache.layout.blocks[i].vals)
            {
                switch (ShaderType.createByName(val.type)) {
                    case Matrix4: uniformMatrix4fv(cache.uniformLocations[uniformIdx++], false, _command.shader.uniforms.matrix4.get(val.name));
                    case Vector4: uniform4fv(cache.uniformLocations[uniformIdx++], _command.shader.uniforms.vector4.get(val.name));
                    case Int    : uniform1f(cache.uniformLocations[uniformIdx++], _command.shader.uniforms.int.get(val.name));
                }
            }
        }
    }

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
     * Location of all non texture uniforms.
     */
    public final uniformLocations : Array<Int>;

    public function new(_layout : ShaderLayout, _textureLocations : Array<Int>, _uniformLocations : Array<Int>)
    {
        layout           = _layout;
        textureLocations = _textureLocations;
        uniformLocations = _uniformLocations;
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
