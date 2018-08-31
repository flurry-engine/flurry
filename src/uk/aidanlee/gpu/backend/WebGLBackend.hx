package uk.aidanlee.gpu.backend;

import uk.aidanlee.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.gpu.batcher.GeometryDrawCommand;
import haxe.ds.Map;
import snow.modules.opengl.GL;
import snow.api.buffers.Uint8Array;
import snow.api.buffers.Float32Array;
import uk.aidanlee.gpu.Renderer.RendererOptions;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderType;
import uk.aidanlee.gpu.backend.IRendererBackend.ShaderLayout;
import uk.aidanlee.gpu.batcher.DrawCommand;
import uk.aidanlee.gpu.geometry.Geometry.BlendMode;
import uk.aidanlee.maths.Rectangle;
import uk.aidanlee.maths.Vector;

/**
 * WebGL backend written against the webGL 1.0 spec (openGL ES 2.0).
 * Uses snows openGL module so it can run on desktops and web platforms.
 * Allows targeting web, osx, and older integrated GPUs (anywhere where openGL 4.5 isn't supported).
 */
class WebGLBackend implements IRendererBackend
{
    /**
     * Access to the renderer who owns this backend.
     */
    final renderer : Renderer;

    /**
     * The single VBO used by the backend.
     */
    final glVbo : GLBuffer;

    /**
     * Vertex buffer used by this backend.
     */
    final vertexBuffer : Float32Array;

    /**
     * Backbuffer display, default target if none is specified.
     */
    final backbuffer : IRenderTarget;

    /**
     * Mapping of shader names to their GL program ID.
     */
    final shaders : Map<Int, Int>;

    /**
     * Cache of shader uniform locations to avoid lots of glGet calls.
     */
    final shaderCache : Map<Int, ShaderLocations>;

    /**
     * Mapping of texture names to their GL texture ID.
     */
    final textures : Map<Int, Int>;

    /**
     * Mapping of render texture names to their GL framebuffer ID.
     */
    final renderTargets : Map<Int, { fbo : Int, texture : Int }>;

    /**
     * Transformation vector used for transforming geometry vertices by a matrix.
     */
    final transformationVector : Vector;

    /**
     * Tracks the position and number of vertices for draw commands uploaded into the dynamic buffer.
     */
    final dynamicCommandRanges : Map<Int, DrawCommandRange>;

    var vertexOffset : Int;

    var floatOffset : Int;

    var byteOffset : Int;

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

    var target   : IRenderTarget;
    var shader   : Shader;
    var clip     : Rectangle;
    var viewport : Rectangle;
    var boundTextures : Array<Int>;

    public function new(_renderer : Renderer, _options : RendererOptions)
    {
        renderer      = _renderer;
        shaders       = new Map();
        shaderCache   = new Map();
        textures      = new Map();
        renderTargets = new Map();
        shaderSequence       = 0;
        textureSequence      = 0;
        renderTargetSequence = 0;

        transformationVector = new Vector();
        dynamicCommandRanges = new Map();
        vertexOffset = 0;
        floatOffset  = 0;
        byteOffset   = 0;

        // Create and bind a singular VBO.
        // Only needs to be bound once since it is used for all drawing.
        vertexBuffer = new Float32Array((_options.maxDynamicVertices + _options.maxUnchangingVertices) * 9);

        glVbo = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, glVbo);
        GL.bufferData(GL.ARRAY_BUFFER, vertexBuffer, GL.DYNAMIC_DRAW);

        GL.enableVertexAttribArray(0);
        GL.enableVertexAttribArray(1);
        GL.enableVertexAttribArray(2);
        GL.vertexAttribPointer(0, 3, GL.FLOAT, false, 9 * Float32Array.BYTES_PER_ELEMENT, 0);
        GL.vertexAttribPointer(1, 4, GL.FLOAT, false, 9 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
        GL.vertexAttribPointer(2, 2, GL.FLOAT, false, 9 * Float32Array.BYTES_PER_ELEMENT, 7 * Float32Array.BYTES_PER_ELEMENT);

        // Create a representation of the backbuffer.
        backbuffer = new BackBuffer(renderTargetSequence, _options.width, _options.height, _options.dpi);

        renderTargets.set(renderTargetSequence++, { fbo : GL.getParameter(GL.FRAMEBUFFER), texture : 0 });

        // Default blend mode
        // TODO : Move this to be a settable property in the geometry or renderer or something
        GL.blendEquationSeparate(GL.FUNC_ADD, GL.FUNC_ADD);
        GL.blendFuncSeparate(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA, GL.ONE, GL.ZERO);

        // Set the clear colour
        GL.clearColor(0.2, 0.2, 0.2, 1.0);

        // Default scissor test
        GL.enable(GL.SCISSOR_TEST);
        GL.scissor(0, 0, backbuffer.width, backbuffer.height);

        // default state
        target   = backbuffer;
        viewport = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        clip     = new Rectangle(0, 0, backbuffer.width, backbuffer.height);
        shader   = null;
        boundTextures = [];
    }

    /**
     * Clear the render target.
     */
    public function clear()
    {
        // Disable the clip to clear the entire target.
        clip.set(0, 0, backbuffer.width, backbuffer.height);
        GL.scissor(0, 0, backbuffer.width, backbuffer.height);

        GL.clear(GL.COLOR_BUFFER_BIT);
    }

    public function clearUnchanging()
    {
        //
    }

    public function preDraw()
    {
        vertexOffset = 0;
        floatOffset  = 0;
        byteOffset   = 0;
    }

    /**
     * Upload geometries to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>) : Void
    {
        var startByteOffset  = byteOffset;
        var startFloatOffset = floatOffset;

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

                    vertexBuffer[floatOffset++] = transformationVector.x;
                    vertexBuffer[floatOffset++] = transformationVector.y;
                    vertexBuffer[floatOffset++] = transformationVector.z;
                    vertexBuffer[floatOffset++] = vertex.color.r;
                    vertexBuffer[floatOffset++] = vertex.color.g;
                    vertexBuffer[floatOffset++] = vertex.color.b;
                    vertexBuffer[floatOffset++] = vertex.color.a;
                    vertexBuffer[floatOffset++] = vertex.texCoord.x;
                    vertexBuffer[floatOffset++] = vertex.texCoord.y;

                    vertexOffset += 1;
                    byteOffset   += (9 * 4);
                }
            }
        }

        GL.bufferSubData(GL.ARRAY_BUFFER, startByteOffset, vertexBuffer.subarray(startFloatOffset, floatOffset));
    }

    /**
     * Upload buffer data to the gpu VRAM.
     * @param _commands Array of commands to upload.
     */
    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>) : Void
    {
        for (command in _commands)
        {
            dynamicCommandRanges.set(command.id, new DrawCommandRange(command.vertices, vertexOffset));

            GL.bufferSubData(GL.ARRAY_BUFFER, byteOffset, command.buffer.subarray(command.startIndex, command.endIndex));

            vertexOffset += command.vertices;
            floatOffset  += command.vertices * 9;
            byteOffset   += command.vertices * 9 * 4;
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
            switch (command.primitive)
            {
                case Points        : GL.drawArrays(GL.POINTS        , range.vertexOffset, range.vertices);
                case Lines         : GL.drawArrays(GL.LINES         , range.vertexOffset, range.vertices);
                case LineStrip     : GL.drawArrays(GL.LINE_STRIP    , range.vertexOffset, range.vertices);
                case Triangles     : GL.drawArrays(GL.TRIANGLES     , range.vertexOffset, range.vertices);
                case TriangleStrip : GL.drawArrays(GL.TRIANGLE_STRIP, range.vertexOffset, range.vertices);
            }

            // Record stats about this draw call.
            if (_recordStats)
            {
                renderer.stats.dynamicDraws++;
                renderer.stats.totalVertices += range.vertices;
            }
        }
    }

    public function postDraw()
    {
        //
    }

    /**
     * Called when the game window is resized.
     * @param _width  new width of the window.
     * @param _height new height of the window.
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

    /**
     * Creates a shader from a vertex and fragment source.
     * @param _vert   Vertex shader source.
     * @param _frag   Fragment shader source.
     * @param _layout Shader layout JSON description.
     * @return Shader
     */
    public function createShader(_vert : String, _frag : String, _layout : ShaderLayout) : Shader
    {
        // Create vertex shader.
        var vertex = GL.createShader(GL.VERTEX_SHADER);
        GL.shaderSource(vertex, _vert);
        GL.compileShader(vertex);

        if (GL.getShaderParameter(vertex, GL.COMPILE_STATUS) == 0)
        {
            throw 'Error Compiling Vertex Shader : ' + GL.getShaderInfoLog(vertex);
        }

        // Create fragment shader.
        var fragment = GL.createShader(GL.FRAGMENT_SHADER);
        GL.shaderSource(fragment, _frag);
        GL.compileShader(fragment);

        if (GL.getShaderParameter(fragment, GL.COMPILE_STATUS) == 0)
        {
            throw 'Error Compiling Fragment Shader : ' + GL.getShaderInfoLog(fragment);
        }

        // Link the shaders into a program.
        var program = GL.createProgram();
        GL.attachShader(program, vertex);
        GL.attachShader(program, fragment);
        GL.linkProgram(program);

        if (GL.getProgramParameter(program, GL.LINK_STATUS) == 0)
        {
            throw 'Error Linking Shader Program : ' + GL.getProgramInfoLog(program);
        }

        // Delete the shaders now that they're linked
        GL.deleteShader(vertex);
        GL.deleteShader(fragment);

        // WebGL has no uniform blocks so all inner values are converted to uniforms
        var textureLocations = [];
        var uniformLocations = [ GL.getUniformLocation(program, "projection"), GL.getUniformLocation(program, "view") ];
        for (texture in _layout.textures)
        {
            textureLocations.push(GL.getUniformLocation(program, texture));
        }
        for (block in _layout.blocks)
        {
            for (uniform in block.vals)
            {
                uniformLocations.push(GL.getUniformLocation(program, uniform.name));
            }
        }

        shaders.set(shaderSequence, program);
        shaderCache.set(shaderSequence, new ShaderLocations(_layout, textureLocations, uniformLocations));

        return new Shader(shaderSequence++);
    }

    /**
     * Removes and frees the resources used by a shader.
     * @param _name Name of the shader.
     */
    public function removeShader(_id : Int)
    {
        GL.deleteProgram(shaders.get(_id));
        shaders.remove(_id);
    }

    /**
     * Creates a new texture given an array of pixel data.
     * @param _name   Name of the texture/
     * @param _pixels Pixel data.
     * @param _width  Width of the texture.
     * @param _height Height of the texture.
     * @return Texture
     */
    public function createTexture(_pixels : Uint8Array, _width : Int, _height : Int) : Texture
    {
        var id = GL.createTexture();
        GL.bindTexture(GL.TEXTURE_2D, id);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, _width, _height, 0, GL.RGBA, GL.UNSIGNED_BYTE, _pixels);

        GL.bindTexture(GL.TEXTURE_2D, 0);

        textures.set(textureSequence, id);
        
        return new Texture(textureSequence++, _width, _height);
    }

    /**
     * Removes and frees the resources used by a texture.
     * @param _name Name of the texture.
     */
    public function removeTexture(_id : Int)
    {
        GL.deleteTexture(textures.get(_id));
        textures.remove(_id);
    }

    public function createRenderTarget(_width : Int, _height : Int) : RenderTexture
    {
        // Create the texture
        var tex = GL.createTexture();
        GL.bindTexture(GL.TEXTURE_2D, tex);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, _width, _height, 0, GL.RGBA, GL.UNSIGNED_BYTE, new Float32Array((_width * _height) * 4));

        GL.bindTexture(GL.TEXTURE_2D, 0);

        // Create the framebuffer
        var fbo = GL.createFramebuffer();
        GL.bindFramebuffer(GL.FRAMEBUFFER, fbo);

        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, tex, 0);

        if (GL.checkFramebufferStatus(GL.FRAMEBUFFER) != GL.FRAMEBUFFER_COMPLETE)
        {
            throw 'Framebuffer Exception : Framebuffer not complete';
        }

        textures.set(textureSequence, tex);
        renderTargets.set(renderTargetSequence, { fbo : fbo, texture : textureSequence });

        return new RenderTexture(renderTargetSequence++, textureSequence++, _width, _height, 1);
    }

    public function removeRenderTarget(_targetID : Int)
    {
        var targetData = renderTargets.get(_targetID);
        var textureID  = textures.get(targetData.texture);

        GL.deleteFramebuffer(targetData.fbo);
        GL.deleteTexture(textureID);

        renderTargets.remove(_targetID);
        textures.remove(targetData.texture);
    }

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
            
            var x = viewport.x *= target.viewportScale;
            var y = viewport.y *= target.viewportScale;
            var w = viewport.w *= target.viewportScale;
            var h = viewport.h *= target.viewportScale;

            // OpenGL works 0x0 is bottom left so we need to flip the y.
            y = target.height - (y + h);
            GL.viewport(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

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
            GL.scissor(Std.int(x), Std.int(y), Std.int(w), Std.int(h));

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
            GL.bindFramebuffer(GL.FRAMEBUFFER, renderTargets.get(target.targetID).fbo);

            if (!_disableStats)
            {
                renderer.stats.targetSwaps++;
            }
        }

        // Apply shader changes.
        if (shader != _command.shader)
        {
            shader = _command.shader;
            GL.useProgram(shaders.get(shader.shaderID));

            if (!_disableStats)
            {
                renderer.stats.shaderSwaps++;
            }
        }
        
        // Apply the shaders uniforms
        // TODO : Only set uniforms if the value has changed.
        setUniforms(_command, _disableStats);

        // Set the blending
        if (_command.blending)
        {
            GL.enable(GL.BLEND);
            GL.blendFuncSeparate(getBlendMode(_command.srcRGB), getBlendMode(_command.dstRGB), getBlendMode(_command.srcAlpha), getBlendMode(_command.dstAlpha));

            if (!_disableStats)
            {
                renderer.stats.blendSwaps++;
            }
        }
        else
        {
            GL.disable(GL.BLEND);

            if (!_disableStats)
            {
                renderer.stats.blendSwaps++;
            }
        }
    }

    /**
     * Apply all of a shaders uniforms.
     * @param _combined     Only required uniform. VP combined matrix.
     * @param _disableStats If stats are to be recorded.
     */
    inline function setUniforms(_command : DrawCommand, _disableStats : Bool)
    {
        // Find this shaders location cache.
        var cache = shaderCache.get(_command.shader.shaderID);

        // TEMP : Set all textures all the time.
        // TODO : Store all bound texture IDs and check before binding textures.
        if (cache.layout.textures.length > _command.textures.length)
        {
            throw 'Error : More textures required by the shader than are provided by the draw command';
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
                var glTextureID  = textures.get(_command.textures[i].textureID);
                if (glTextureID != boundTextures[i])
                {
                    GL.activeTexture(GL.TEXTURE0 + i);
                    GL.bindTexture(GL.TEXTURE_2D, textures.get(_command.textures[i].textureID));

                    GL.uniform1i(cache.textureLocations[i], i);

                    boundTextures[i] = glTextureID;

                    if (!_disableStats)
                    {
                        renderer.stats.textureSwaps++;
                    }
                }
            }
        }

        // Write the default matrix uniforms
        GL.uniformMatrix4fv(cache.uniformLocations[0], false, _command.projection.elements);
        GL.uniformMatrix4fv(cache.uniformLocations[1], false, _command.view.elements);

        // Start at uniform index 2 since the first two are the default matrix uniforms.
        var uniformIdx = 2;
        for (i in 0...cache.layout.blocks.length)
        {
            for (val in cache.layout.blocks[i].vals)
            {
                switch (ShaderType.createByName(val.type)) {
                    case Matrix4: GL.uniformMatrix4fv(cache.uniformLocations[uniformIdx++], false, _command.shader.matrix4.get(val.name).elements);
                    case Vector4: GL.uniform4fv(cache.uniformLocations[uniformIdx++], vectorToFloatArray(_command.shader.vector4.get(val.name)));
                    case Int    : GL.uniform1f(cache.uniformLocations[uniformIdx++], _command.shader.int.get(val.name));
                }
            }
        }
    }

    inline function vectorToFloatArray(_vector : Vector) : Float32Array
    {
        var array = new Float32Array(4);
        array[0] = _vector.x;
        array[1] = _vector.y;
        array[2] = _vector.z;
        array[3] = _vector.w;

        return array;
    }

    inline function getBlendMode(_mode : BlendMode) : Int
    {
        return switch (_mode)
        {
            case Zero             : GL.ZERO;
            case One              : GL.ONE;
            case SrcAlphaSaturate : GL.SRC_ALPHA_SATURATE;
            case SrcColor         : GL.SRC_COLOR;
            case OneMinusSrcColor : GL.ONE_MINUS_SRC_COLOR;
            case SrcAlpha         : GL.SRC_ALPHA;
            case OneMinusSrcAlpha : GL.ONE_MINUS_SRC_ALPHA;
            case DstAlpha         : GL.DST_ALPHA;
            case OneMinusDstAlpha : GL.ONE_MINUS_DST_ALPHA;
            case DstColor         : GL.DST_COLOR;
            case OneMinusDstColor : GL.ONE_MINUS_DST_COLOR;
            case _: 0;
        }
    }
}

private class ShaderLocations
{
    public final layout : ShaderLayout;

    public final textureLocations : Array<GLUniformLocation>;

    public final uniformLocations : Array<GLUniformLocation>;

    public function new(_layout : ShaderLayout, _textureLocations : Array<GLUniformLocation>, _uniformLocations : Array<GLUniformLocation>)
    {
        layout           = _layout;
        textureLocations = _textureLocations;
        uniformLocations = _uniformLocations;
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
