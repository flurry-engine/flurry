package uk.aidanlee.gpu.backend;

import haxe.io.Bytes;
import haxe.ds.Map;
import cpp.Float32;
import cpp.Pointer;
import opengl.GL.*;
import opengl.GL.GLSync;
import opengl.WebGL;
import snow.api.buffers.Float32Array;
import snow.api.buffers.Uint8Array;
import snow.api.Debug.def;
import uk.aidanlee.gpu.Renderer.RendererOptions;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderType;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderLayout;
import uk.aidanlee.gpu.geometry.Geometry.BlendMode;
import uk.aidanlee.gpu.batcher.DrawCommand;
import uk.aidanlee.gpu.batcher.GeometryDrawCommand;
import uk.aidanlee.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.gpu.IRenderTarget;
import uk.aidanlee.gpu.Shader;
import uk.aidanlee.gpu.Texture;
import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.maths.Matrix;

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
class GL45Backend implements IRendererBackend
{
    /**
     * Access to the renderer who owns this backend.
     */
    final renderer : Renderer;

    /**
     * If we will be using bindless textures.
     */
    final bindless : Bool;

    /**
     * The single VBO used by the backend.
     */
    final glVbo : Int;

    /**
     * The single VAO which is bound once when the backend is created.
     */
    final glVao : Int;

    /**
     * Mapping of shader names to their GL program ID.
     */
    final shaders : Map<Int, Int>;

    /**
     * Cache of shader uniform locations to avoid lots of glGet calls.
     */
    final shaderCache : Map<Int, ShaderLocations>;

    /**
     * Mapping of texture IDs to their GL texture ID.
     */
    final textures : Map<Int, Int>;

    /**
     * All of the created textures handles.
     * This would be a map but for some reason hxcpp doesn't like cpp.UInt64 values.
     */
    final textureHandles : Array<cpp.UInt64>;

    /**
     * Mapping of render texture names to their GL framebuffer ID.
     */
    final renderTargets : Map<Int, { fbo : Int, texture : Int }>;

    /**
     * Backbuffer display, default target if none is specified.
     */
    final backbuffer : IRenderTarget;

    /**
     * Tracks, stores, and uploads unchaning buffer data and its required state.
     */
    final unchangingStorage : UnchangingBuffer;

    /**
     * Tracks the position and number of vertices for draw commands uploaded into the dynamic buffer.
     */
    final dynamicCommandRanges : Map<Int, DrawCommandRange>;

    /**
     * These ranges describe writable chunks of the vertex buffer.
     * This is used for triple buffering with mapped buffers where only one chunk can be written to at a time.
     */
    final bufferRanges : Array<BufferRange>;

    /**
     * The persistently mapped float buffer to write vertex data into.
     * This will be three times the requested float size for triple buffering.
     */
    final vertexBuffer : Array<Float32>;

    /**
     * Constant vector instance which is used to transform vertices when copying into the vertex buffer.
     */
    final transformationVector : Vector;

    /**
     * Index pointing to the current writable buffer range.
     */
    var bufferRangeIndex : Int;

    /**
     * The index into the vertex buffer to write.
     * Writing more floats must increment this value. Set the to current ranges offset in preDraw.
     */
    var floatOffset : Int;

    /**
     * Offset to use when calling openngl draw commands.
     * Writing more verticies must increment this value. Set the to current ranges offset in preDraw.
     */
    var vertexOffset : Int;

    /**
     * Sequence number texture IDs.
     * For each generated texture this number is incremented and given to the texture as a unique ID.
     * Allows batchers to sort textures.
     */
    var textureSequence : Int;

    /**
     * Sequence number shader IDs.
     * For each generated shader this number is incremented and given to the shader as a unique ID.
     * Allows batchers to sort shaders.
     */
    var shaderSequence : Int;

    /**
     * Sequence number render texture IDs.
     * For each generated render texture this number is incremented and given to the render texture as a unique ID.
     * Allows batchers to sort render textures.
     */
    var renderTargetSequence : Int;

    // GL state variables

    var viewport : Rectangle;
    var clip     : Rectangle;
    var target   : IRenderTarget;
    var shader   : Shader;

    /**
     * Creates a new openGL 4.5 renderer.
     * @param _renderer           Access to the renderer which owns this backend.
     * @param _dynamicVertices    The maximum number of dynamic vertices in the buffer.
     * @param _unchangingVertices The maximum number of static vertices in the buffer.
     */
    public function new(_renderer : Renderer, _options : RendererOptions)
    {
        _options.backend = def(_options.backend, {});

        renderer       = _renderer;
        shaders        = new Map();
        shaderCache    = new Map();
        textures       = new Map();
        renderTargets  = new Map();
        textureHandles = [ for (i in 0...256) 0 ];
        shaderSequence       = 0;
        textureSequence      = 0;
        renderTargetSequence = 0;

        // Check for ARB_bindless_texture support
        bindless = def(_options.backend.bindless, false);

        // Create and bind a singular VBO.
        // Only needs to be bound once since it is used for all drawing.

        var totalBufferVerts  = _options.maxUnchangingVertices + (_options.maxDynamicVertices * 3);
        var totalBufferFloats = totalBufferVerts  * 9;
        var totalBufferBytes  = totalBufferFloats * 4;

        // Create an empty buffer.
        var vbo = [ 0 ];
        glCreateBuffers(1, vbo);
        untyped __cpp__("glNamedBufferStorage({0}, {1}, nullptr, {2})", vbo[0], totalBufferBytes, GL_DYNAMIC_STORAGE_BIT | GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT);

        // Create the vao and bind the vbo to it.
        var vao = [ 0 ];
        glCreateVertexArrays(1, vao);
        glVertexArrayVertexBuffer(vao[0], 0, vbo[0], 0, Float32Array.BYTES_PER_ELEMENT * 9);

        // Enable and setup the vertex attributes for this batcher.
        glEnableVertexArrayAttrib(vao[0], 0);
        glEnableVertexArrayAttrib(vao[0], 1);
        glEnableVertexArrayAttrib(vao[0], 2);

        glVertexArrayAttribFormat(vbo[0], 0, 3, GL_FLOAT, false, 0);
        glVertexArrayAttribFormat(vbo[0], 1, 4, GL_FLOAT, false, Float32Array.BYTES_PER_ELEMENT * 3);
        glVertexArrayAttribFormat(vbo[0], 2, 2, GL_FLOAT, false, Float32Array.BYTES_PER_ELEMENT * 7);

        glVertexArrayAttribBinding(vao[0], 0, 0);
        glVertexArrayAttribBinding(vao[0], 1, 0);
        glVertexArrayAttribBinding(vao[0], 2, 0);

        glVbo = vbo[0];
        glVao = vao[0];

        // Bind our VAO once.
        glBindVertexArray(glVao);

        // Define the dynamic vertex triple buffering ranges
        // These ranges will map into the array pointer.
        // Offset to ignore the unchanging region.

        var floatSegmentSize = _options.maxDynamicVertices * 9;
        var floatOffsetSize  = _options.maxUnchangingVertices * 9;

        bufferRangeIndex = 0;
        bufferRanges = [
            new BufferRange(floatOffsetSize                         , _options.maxUnchangingVertices),
            new BufferRange(floatOffsetSize + floatSegmentSize      , _options.maxUnchangingVertices +  _options.maxDynamicVertices),
            new BufferRange(floatOffsetSize + (floatSegmentSize * 2), _options.maxUnchangingVertices + (_options.maxDynamicVertices * 2))
        ];

        // create a new storage container for holding unchaning commands.
        unchangingStorage    = new UnchangingBuffer(_options.maxUnchangingVertices);
        dynamicCommandRanges = new Map();
        transformationVector = new Vector();

        // Map the buffer into an unmanaged array.
        var ptr : Pointer<Float32> = Pointer.fromRaw(glMapNamedBufferRange(glVbo, 0, totalBufferBytes, GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT)).reinterpret();
        vertexBuffer = ptr.toUnmanagedArray(totalBufferFloats);

        // Create a representation of the backbuffer and manually insert it into the target structure.
        var backbufferID = [ 0 ];
        glGetIntegerv(GL_FRAMEBUFFER, backbufferID);

        backbuffer = new BackBuffer(renderTargetSequence, _options.width, _options.height, _options.dpi);

        renderTargets.set(renderTargetSequence++, { fbo : backbufferID[0], texture : 0});

        // Default blend mode
        // TODO : Move this to be a settable property in the geometry or renderer or something
        glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
        glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);

        // Set the clear colour
        glClearColor(0.2, 0.2, 0.2, 1.0);

        // Default scissor test
        glEnable(GL_SCISSOR_TEST);
        glScissor(0, 0, backbuffer.width, backbuffer.height);

        // default state
        viewport = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        clip     = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        target   = backbuffer;
        shader   = null;
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
        unlockBuffer(bufferRanges[bufferRangeIndex]);

        floatOffset  = bufferRanges[bufferRangeIndex].fltOffset;
        vertexOffset = bufferRanges[bufferRangeIndex].vtxOffset;
    }

    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>)
    {
        for (command in _commands)
        {
            if (command.unchanging)
            {
                var unchangingOffset = unchangingStorage.currentVertices * 9;

                if (unchangingStorage.exists(command.id))
                {
                    continue;
                }

                if (unchangingStorage.add(command))
                {
                    for (geom in command.geometry)
                    {
                        var matrix = geom.transformation.transformation;

                        for (vertex in geom.vertices)
                        {
                            // Copy the vertex into another vertex.
                            // This allows us to apply the transformation without permanently modifying the original geometry.
                            transformationVector.copyFrom(vertex.position);
                            transformationVector.transform(matrix);

                            vertexBuffer[unchangingOffset++] = transformationVector.x;
                            vertexBuffer[unchangingOffset++] = transformationVector.y;
                            vertexBuffer[unchangingOffset++] = transformationVector.z;
                            vertexBuffer[unchangingOffset++] = vertex.color.r;
                            vertexBuffer[unchangingOffset++] = vertex.color.g;
                            vertexBuffer[unchangingOffset++] = vertex.color.b;
                            vertexBuffer[unchangingOffset++] = vertex.color.a;
                            vertexBuffer[unchangingOffset++] = vertex.texCoord.x;
                            vertexBuffer[unchangingOffset++] = vertex.texCoord.y;
                        }
                    }

                    continue;
                }
            }

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

                    vertexBuffer[floatOffset++] = transformationVector.x;
                    vertexBuffer[floatOffset++] = transformationVector.y;
                    vertexBuffer[floatOffset++] = transformationVector.z;
                    vertexBuffer[floatOffset++] = vertex.color.r;
                    vertexBuffer[floatOffset++] = vertex.color.g;
                    vertexBuffer[floatOffset++] = vertex.color.b;
                    vertexBuffer[floatOffset++] = vertex.color.a;
                    vertexBuffer[floatOffset++] = vertex.texCoord.x;
                    vertexBuffer[floatOffset++] = vertex.texCoord.y;

                    vertexOffset++;
                }
            }
        }
    }

    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>)
    {
        for (command in _commands)
        {
            if (command.unchanging)
            {
                var unchangingOffset = unchangingStorage.currentVertices * 9;

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

            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset));

            for (i in command.startIndex...command.endIndex)
            {
                vertexBuffer[floatOffset++] = command.buffer[i];
            }

            vertexOffset += command.vertices;
        }
    }

    public function submitCommands(_commands : Array<DrawCommand>, _recordStats : Bool = true)
    {
        for (command in _commands)
        {
            if (command.unchanging)
            {
                if (unchangingStorage.exists(command.id))
                {
                    var offset = unchangingStorage.get(command.id);

                    setState(command, !_recordStats);

                    // Draw the actual vertices
                    switch (command.primitive)
                    {
                        case Points        : glDrawArrays(GL_POINTS        , offset, command.vertices);
                        case Lines         : glDrawArrays(GL_LINES         , offset, command.vertices);
                        case LineStrip     : glDrawArrays(GL_LINE_STRIP    , offset, command.vertices);
                        case Triangles     : glDrawArrays(GL_TRIANGLES     , offset, command.vertices);
                        case TriangleStrip : glDrawArrays(GL_TRIANGLE_STRIP, offset, command.vertices);
                    }

                    // Record stats about this draw call.
                    if (_recordStats)
                    {
                        renderer.stats.dynamicDraws++;
                        renderer.stats.totalVertices += command.vertices;
                    }

                    continue;
                }
            }

            var range = dynamicCommandRanges.get(command.id);

            // Change the state so the vertices are drawn correctly.
            setState(command, !_recordStats);

            // Draw the actual vertices
            switch (command.primitive)
            {
                case Points        : glDrawArrays(GL_POINTS        , range.vertexOffset, range.vertices);
                case Lines         : glDrawArrays(GL_LINES         , range.vertexOffset, range.vertices);
                case LineStrip     : glDrawArrays(GL_LINE_STRIP    , range.vertexOffset, range.vertices);
                case Triangles     : glDrawArrays(GL_TRIANGLES     , range.vertexOffset, range.vertices);
                case TriangleStrip : glDrawArrays(GL_TRIANGLE_STRIP, range.vertexOffset, range.vertices);
            }

            // Record stats about this draw call.
            if (_recordStats)
            {
                renderer.stats.dynamicDraws++;
                renderer.stats.totalVertices += range.vertices;
            }
        }
    }

    /**
     * Locks the range we are currenly writing to and increments the index.
     */
    public function postDraw()
    {
        lockBuffer(bufferRanges[bufferRangeIndex]);
        bufferRangeIndex = (bufferRangeIndex + 1) % 3;
    }

    /**
     * Updates the size of the backbuffer to the new size of the window.
     * @param _width  Window width.
     * @param _height Window height.
     */
    public function resize(_width : Int, _height : Int)
    {
        backbuffer.width  = _width;
        backbuffer.height = _height;
    }

    /**
     * Unmap the buffer and iterate over all resources deleting their resources and remove them from the structure.
     */
    public function cleanup()
    {
        glUnmapNamedBuffer(glVbo);

        for (shader in shaders.keys())
        {
            removeShader(shader);
        }

        for (texture in textures.keys())
        {
            removeTexture(texture);
        }

        for (target in renderTargets.keys())
        {
            removeRenderTarget(target);
        }
    }

    // #region Resource management.

    /**
     * Compiles and links together a shader program from the provided vertex and fragment shader.
     * 
     * TODO : decide upon using WebGL class or not. Mixing between the two looks rather ugly.
     * @param _vert   Vertex source.
     * @param _frag   Fragment source.
     * @param _layout Shader layout JSON description.
     * @return Shader
     */
    public function createShader(_vert : String, _frag : String, _layout : ShaderLayout) : Shader
    {
        // Create vertex shader.
        var vertex = glCreateShader(GL_VERTEX_SHADER);
        WebGL.shaderSource(vertex, _vert);
        glCompileShader(vertex);

        if (WebGL.getShaderParameter(vertex, GL_COMPILE_STATUS) == 0)
        {
            throw 'Error Compiling Vertex Shader : ' + WebGL.getShaderInfoLog(vertex);
        }

        // Create fragment shader.
        var fragment = glCreateShader(GL_FRAGMENT_SHADER);
        WebGL.shaderSource(fragment, _frag);
        glCompileShader(fragment);

        if (WebGL.getShaderParameter(fragment, GL_COMPILE_STATUS) == 0)
        {
            throw 'Error Compiling Fragment Shader : ' + WebGL.getShaderInfoLog(fragment);
        }

        // Link the shaders into a program.
        var program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);

        if (WebGL.getProgramParameter(program, GL_LINK_STATUS) == 0)
        {
            throw 'Error Linking Shader Program : ' + WebGL.getProgramInfoLog(program);
        }

        // Delete the shaders now that they're linked
        glDeleteShader(vertex);
        glDeleteShader(fragment);

        // Get the location of all textures and storage blocks in the gl program.
        var textureLocations = [];
        var blockLocations   = [ glGetProgramResourceIndex(program, GL_SHADER_STORAGE_BLOCK, "defaultMatrices") ];
        for (texture in _layout.textures)
        {
            textureLocations.push(glGetUniformLocation(program, texture));
        }
        for (block in _layout.blocks)
        {
            blockLocations.push(glGetProgramResourceIndex(program, GL_SHADER_STORAGE_BLOCK, block.name));
        }

        // Setup haxe bytes and gl buffers for all storage blocks.
        var blockBytes   = new Array<Bytes>();
        var blockBuffers = new Array<Int>();

        // Allocate for the default matrices block.
        var data = Bytes.alloc(128);
        var ssbo = [ 0 ];
        glCreateBuffers(1, ssbo);

        blockBuffers.push(ssbo[0]);
        blockBytes.push(data);

        // Create a GL buffer and allocate bytes for each user defined bytes.
        for (block in _layout.blocks)
        {
            var bytesSize = 0;
            for (val in block.vals)
            {
                switch (ShaderType.createByName(val.type))
                {
                    case Matrix4: bytesSize += 64;
                    case Vector4: bytesSize += 16;
                    case Int    : bytesSize +=  4;
                }
            }
            var bytesData = Bytes.alloc(bytesSize);
            var ssbo      = [ 0 ];
            glCreateBuffers(1, ssbo);

            blockBuffers.push(ssbo[0]);
            blockBytes.push(bytesData);
        }

        // Cache the layout, locations, buffer IDs, and bytes information
        shaders.set(shaderSequence, program);
        shaderCache.set(shaderSequence, new ShaderLocations(_layout, textureLocations, blockLocations, blockBuffers, blockBytes));

        return new Shader(shaderSequence++);
    }

    /**
     * Deletes a GL program and removes it from the shader storage.
     * @param _id Unique shader ID.
     */
    public function removeShader(_id : Int)
    {
        glDeleteProgram(shaders.get(_id));
        shaders.remove(_id);
    }

    /**
     * Create a new texture.
     * @param _pixels R8G8B8A8 pixel data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
    public function createTexture(_pixels : Uint8Array, _width : Int, _height : Int) : Texture
    {
        var ids = [ 0 ];
        glCreateTextures(GL_TEXTURE_2D, 1, ids);

        glTextureParameteri(ids[0], GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTextureParameteri(ids[0], GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTextureParameteri(ids[0], GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTextureParameteri(ids[0], GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        glTextureStorage2D(ids[0], 1, GL_RGBA8, _width, _height);
        glTextureSubImage2D(ids[0], 0, 0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, _pixels.toBytes().getData());

        textures.set(textureSequence, ids[0]);

        if (bindless)
        {
            var handle = glGetTextureHandleARB(ids[0]);
            glMakeTextureHandleResidentARB(handle);

            textureHandles[textureSequence] = handle;
        }
        
        return new Texture(textureSequence++, _width, _height);
    }

    /**
     * Remove the resources used by a texture.
     * @param _id Unique texture ID.
     */
    public function removeTexture(_id : Int)
    {
        if (bindless)
        {
            glMakeTextureHandleNonResidentARB(textureHandles[_id]);
        }

        glDeleteTextures(0, [ textures.get(_id) ]);
        textures.remove(_id);
    }

    /**
     * Create a new render target.
     * @param _width  Width of the target.
     * @param _height Height of the target.
     * @return RenderTexture
     */
    public function createRenderTarget(_width : Int, _height : Int) : RenderTexture
    {
        // Create the texture
        var tex = [ 0 ];
        glCreateTextures(GL_TEXTURE_2D, 1, tex);

        glTextureParameteri(tex[0], GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTextureParameteri(tex[0], GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTextureParameteri(tex[0], GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTextureParameteri(tex[0], GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        glTextureStorage2D(tex[0], 1, GL_RGBA8, _width, _height);

        // Create the framebuffer
        var fbo = [ 0 ];
        glCreateFramebuffers(1, fbo);
        glNamedFramebufferTexture(fbo[0], GL_COLOR_ATTACHMENT0, tex[0], 0);

        if (glCheckNamedFramebufferStatus(fbo[0], GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            throw 'Framebuffer Exception : Framebuffer not complete';
        }

        textures.set(textureSequence, tex[0]);
        renderTargets.set(renderTargetSequence, { fbo : fbo[0], texture : textureSequence });

        if (bindless)
        {
            var handle = glGetTextureHandleARB(tex[0]);
            glMakeTextureHandleResidentARB(handle);

            textureHandles[textureSequence] = handle;
        }

        return new RenderTexture(renderTargetSequence++, textureSequence++, _width, _height, 1);
    }

    /**
     * Remove the resources used by a render target.
     * @param _targetID  Unique render target ID.
     * @param _textureID Unique texture ID.
     */
    public function removeRenderTarget(_targetID : Int)
    {
        var targetData = renderTargets.get(_targetID);
        var textureID  = textures.get(targetData.texture);

        if (bindless)
        {
            glMakeImageHandleNonResidentARB(textureHandles[targetData.texture]);
        }

        glDeleteFramebuffers(1, [ targetData.fbo ]);
        glDeleteTextures(1, [ textureID ]);

        renderTargets.remove(targetData.fbo);
        textures.remove(targetData.texture);
    }

    // #endregion

    /**
     * Update the openGL state so it can draw the provided command.
     * @param _command      Command to set the state for.
     * @param _disableStats If stats are to be recorded.
     */
    inline function setState(_command : DrawCommand, _disableStats : Bool)
    {
        // Set the viewport.
        // If the viewport of the command is null then the backbuffer size is used (size of the window).
        var cmdViewport = _command.viewport != null ? _command.viewport : new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        if (!viewport.equals(cmdViewport))
        {
            viewport.set(cmdViewport.x, cmdViewport.y, cmdViewport.w, cmdViewport.h);

            var x = viewport.x *= target.viewportScale;
            var y = viewport.y *= target.viewportScale;
            var w = viewport.w *= target.viewportScale;
            var h = viewport.h *= target.viewportScale;

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            y = target.height - (y + h);
            glViewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

            if (!_disableStats)
            {
                renderer.stats.viewportSwaps++;
            }
        }

        // Apply the scissor clip.
        var cmdClip = _command.clip != null ? _command.clip : new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        if (!cmdClip.equals(clip))
        {
            clip.copyFrom(cmdClip);

            var x = clip.x *= target.viewportScale;
            var y = clip.y *= target.viewportScale;
            var w = clip.w *= target.viewportScale;
            var h = clip.h *= target.viewportScale;

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            y = target.height - (y + h);
            glScissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

            if (!_disableStats)
            {
                renderer.stats.scissorSwaps++;
            }
        }

        // Set the render target.
        // If the target is null then the backbuffer is used.
        var cmdTarget = _command.target != null ? _command.target : backbuffer;
        if (target.targetID != cmdTarget.targetID)
        {
            target = cmdTarget;
            glBindFramebuffer(GL_FRAMEBUFFER, renderTargets.get(target.targetID).fbo);

            if (!_disableStats)
            {
                renderer.stats.targetSwaps++;
            }
        }

        // Apply shader changes.
        if (shader != _command.shader)
        {
            shader = _command.shader;
            glUseProgram(shaders.get(shader.shaderID));
            
            if (!_disableStats)
            {
                renderer.stats.shaderSwaps++;
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
                renderer.stats.blendSwaps++;
            }
        }
        else
        {
            glDisable(GL_BLEND);

            if (!_disableStats)
            {
                renderer.stats.blendSwaps++;
            }
        }
    }

    /**
     * Apply all of a shaders uniforms.
     * @param _command      Command to set the state for.
     * @param _disableStats If stats are to be recorded.
     */
    inline function setUniforms(_command : DrawCommand, _disableStats : Bool)
    {
        var cache = shaderCache.get(_command.shader.shaderID);

        // TEMP : Set all textures all the time.
        // TODO : Store all bound texture IDs and check before binding textures.

        if (cache.layout.textures.length > _command.textures.length)
        {
            throw 'Error : More textures required by the shader than are provided by the draw command';
        }
        else
        {
            if (bindless)
            {
                var handlesToBind = [ for (id in _command.textures) textureHandles[id.textureID] ];
                glUniformHandleui64vARB(0, handlesToBind.length, handlesToBind);
            }
            else
            {
                // then go through each texture and bind it if it isn't already.
                var texturesToBind : Array<Int> = [ for (id in _command.textures) textures.get(id.textureID) ];
                glBindTextures(0, texturesToBind.length, texturesToBind);

                if (!_disableStats)
                {
                    renderer.stats.textureSwaps++;
                }
            }
        }

        // TEMP : Always writing all uniform values into SSBOs.
        // TODO : Only update SSBOs when values have actually changed.
        
        // Write the default matrices into the ssbo.
        var pos = 0;
        for (el in _command.projection.elements)
        {
            cache.blockBytes[0].setFloat(pos, el);
            pos += 4;
        }
        for (el in _command.view.elements)
        {
            cache.blockBytes[0].setFloat(pos, el);
            pos += 4;
        }

        glNamedBufferData(cache.blockBuffers[0], cache.blockBytes[0].length, cache.blockBytes[0].getData(), GL_DYNAMIC_DRAW);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, cache.blockBuffers[0]);

        // Write user data into the blocks.
        // Some arrays are incremented by 1 to access the correct data since the default block is stored.
        // This is not true for the blocks in the layout since they store user defined ones.
        for (i in 0...cache.layout.blocks.length)
        {
            var bytePosition = 0;
            for (val in cache.layout.blocks[i].vals)
            {
                switch (ShaderType.createByName(val.type)) {
                    case Matrix4: bytePosition += writeMatrix4(cache.blockBytes[i + 1], bytePosition, _command.shader.matrix4.get(val.name));
                    case Vector4: bytePosition += writeVector4(cache.blockBytes[i + 1], bytePosition, _command.shader.vector4.get(val.name));
                    case Int    : bytePosition +=     writeInt(cache.blockBytes[i + 1], bytePosition, _command.shader.int.get(val.name));
                }
            }

            glNamedBufferData(cache.blockBuffers[i + 1], cache.blockBytes[i + 1].length, cache.blockBytes[i + 1].getData(), GL_DYNAMIC_DRAW);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, i + 1, cache.blockBuffers[i + 1]);
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
     * Returns the equivalent openGL blend mode from the abstract blend enum
     * @param _mode Blend mode to fetch.
     * @return Int
     */
    inline function getBlendMode(_mode : BlendMode) : Int
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
}

private class ShaderLocations
{
    public final layout : ShaderLayout;

    public final textureLocations : Array<Int>;

    public final blockLocations : Array<Int>;

    public final blockBuffers : Array<Int>;

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
    public final fltOffset : Int;

    /**
     * Vertex offset of this buffer range.
     */
    public final vtxOffset : Int;

    /**
     * OpenGL sync object used to lock this buffer range.
     */
    public var sync : GLSync;

    public function new(_flt : Int, _vtx : Int)
    {
        fltOffset = _flt;
        vtxOffset = _vtx;
    }
}

/**
 * Manages all of the unchanging batches currently stored.
 */
private class UnchangingBuffer
{
    /**
     * The current number of vertices we have stored.
     */
    public var currentVertices (default, null) : Int;

    /**
     * The total number of vertices we can store.
     */
    final maxVertices : Int;

    /**
     * Maps a draw commands hash to the vertex offset of that commands vertices in the unchanging buffer range.
     */
    final currentRanges : Map<Int, Int>;

    public function new(_maxVertices)
    {
        maxVertices     = _maxVertices;
        currentVertices = 0;

        currentRanges   = new Map();
    }

    /**
     * Attempts to add a draw command into the unchanging range.
     * @param _command The command to add.
     * @return Bool if the command was successfully added.
     */
    public function add(_command : DrawCommand) : Bool
    {
        if ((currentVertices + _command.vertices) <= maxVertices)
        {
            currentRanges.set(_command.id, currentVertices);
            currentVertices += _command.vertices;

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
    public function get(_id : Int) : Int
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
