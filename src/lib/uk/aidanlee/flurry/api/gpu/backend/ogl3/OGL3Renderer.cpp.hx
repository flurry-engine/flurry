package uk.aidanlee.flurry.api.gpu.backend.ogl3;

import uk.aidanlee.flurry.api.gpu.backend.ogl3.OGL3ShaderInformation.OGL3ShaderInputElement;
import uk.aidanlee.flurry.api.gpu.pipeline.VertexElement.VertexType;
import haxe.ds.Vector;
import opengl.OpenGL.GLuint;
import uk.aidanlee.flurry.FlurryConfig.FlurryRendererOgl3Config;
import uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import sdl.SDL;
import sdl.Window;
import sdl.GLContext;
import glad.Glad;
import opengl.OpenGL.*;
import haxe.Exception;
import haxe.io.ArrayBufferView;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineID;
import uk.aidanlee.flurry.api.gpu.pipeline.PipelineState;
import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader.Ogl3Shader;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.builtin.ShaderResource;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
import uk.aidanlee.flurry.api.gpu.backend.ogl3.output.VertexOutput;
import uk.aidanlee.flurry.api.gpu.backend.ogl3.output.IndexOutput;
import uk.aidanlee.flurry.api.gpu.backend.ogl3.output.UniformOutput;

using Safety;

class OGL3Renderer extends Renderer
{
    final window : Window;

    final glContext : GLContext;

    final clearColour : Vec4;

    final glVao : Int;

    final glVertexBuffer : Int;

    final glIndexBuffer : Int;

    final glUniformBuffer : Int;

    final glUniformAlignment : Int;

    final pipelines : Vector<Null<PipelineState>>;

    final surfaces : Vector<Null<OGL3SurfaceInformation>>;

    final shaderResources : Map<ResourceID, OGL3ShaderInformation>;

    final textureResources : Map<ResourceID, GLuint>;

    final graphicsContext : OGL3GraphicsContext;

    public function new(_resourceEvents : ResourceEvents, _displayEvents : DisplayEvents, _windowConfig : FlurryWindowConfig, _rendererConfig : FlurryRendererOgl3Config)
    {
        super(_resourceEvents);

        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        window    = SDL.createWindow(_windowConfig.title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _windowConfig.width, _windowConfig.height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
        glContext = SDL.GL_CreateContext(window);

        clearColour        = _rendererConfig.clearColour.clone();
        glVao              = 0;
        glVertexBuffer     = 0;
        glIndexBuffer      = 0;
        glUniformBuffer    = 0;
        glUniformAlignment = 0;
        pipelines          = new Vector(1024);
        surfaces           = new Vector(1024);
        shaderResources    = [];
        textureResources   = [];

        SDL.GL_MakeCurrent(window, glContext);

        if (Glad.gladLoadGLLoader(untyped __cpp__('&SDL_GL_GetProcAddress')) == 0)
        {
            throw new Exception('Failed to load opengl');
        }

        // 3.3 core profiles need at least one VAO bound.
        glGenVertexArrays(1, glVao);
        glBindVertexArray(glVao);
        
        // Generate our buffers.
        glGenBuffers(1, glVertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, glVertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, _rendererConfig.vertexBufferSize, null, GL_DYNAMIC_DRAW);
        
        glGenBuffers(1, glIndexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glIndexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _rendererConfig.indexBufferSize, null, GL_DYNAMIC_DRAW);
        
        glGenBuffers(1, glUniformBuffer);
        glBindBuffer(GL_UNIFORM_BUFFER, glUniformBuffer);
        glBufferData(GL_UNIFORM_BUFFER, _rendererConfig.uniformBufferSize, null, GL_DYNAMIC_DRAW);

        // Fetch some info on the devices support.
        glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, glUniformAlignment);

        // Set some openGL state which will remain constant.
        glClearDepth(1);
        glClearStencil(0);
        glBlendColor(1, 1, 1, 1);

        surfaces[SurfaceID.backbuffer] = createBackBuffer(_windowConfig.width, _windowConfig.height);

        graphicsContext = new OGL3GraphicsContext(
            new VertexOutput(glVertexBuffer, _rendererConfig.vertexBufferSize),
            new IndexOutput(glIndexBuffer, _rendererConfig.indexBufferSize),
            new UniformOutput(glUniformBuffer, _rendererConfig.uniformBufferSize, glUniformAlignment),
            pipelines,
            surfaces,
            shaderResources,
            textureResources);
    }

	public function getGraphicsContext() : GraphicsContext
    {
        // Clear all non backbuffer surfaces with transparent white.
        glClearColor(1, 1, 1, 0);

        for (i in 0...surfaces.length)
        {
            switch surfaces[i]
            {
                case null:
                    //
                case surface if (i != SurfaceID.backbuffer):
                    glBindFramebuffer(GL_FRAMEBUFFER, surface.frameBuffer);
                    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
            }
        }

        // Clear the backbuffer surface with the clear colour.
        switch surfaces[SurfaceID.backbuffer]
        {
            case null:
                throw new Exception('Backbuffer surface was null');
            case backbuffer:
                glClearColor(clearColour.x, clearColour.y, clearColour.z, clearColour.w);
                glBindFramebuffer(GL_FRAMEBUFFER, backbuffer.frameBuffer);
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
        }

        return graphicsContext;
	}

	public function present()
    {
        switch surfaces[SurfaceID.backbuffer]
        {
            case null:
                throw new Exception('Backbuffer surface was null');
            case backbuffer:
                // OpenGL treats origins at the bottom left of the window.
                // We want things to be the top left for consistency, so blit to the backbuffer flipping on the vertical axis.
                glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
                glBindFramebuffer(GL_READ_FRAMEBUFFER, backbuffer.frameBuffer);
                glBlitFramebuffer(
                    0, 0, backbuffer.width, backbuffer.height,
                    0, backbuffer.height, backbuffer.width, 0,
                    GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT,
                    GL_NEAREST
                );

                SDL.GL_SwapWindow(window);
        }
    }

	public function createPipeline(_state : PipelineState)
    {
		final id = new PipelineID(getNextPipelineID());

        pipelines[id] = _state;

        return id;
	}

	public function deletePipeline(_id : PipelineID)
    {
        pipelines[_id] = null;
    }

	public function createSurface(_width : Int, _height : Int)
    {
        final id = getNextSurfaceID();
        
        surfaces[id] = createBackBuffer(_width, _height);

		return new SurfaceID(id);
	}

	public function deleteSurface(_id : SurfaceID)
    {
        switch surfaces[_id]
        {
            case null:
                //
            case surface:
                glDeleteTextures(1, surface.texture);
                glDeleteRenderbuffers(1, surface.renderBuffer);
                glDeleteFramebuffers(1, surface.frameBuffer);

                surfaces[_id] = null;
        }
    }

	public function updateTexture(_frame : PageFrameResource, _data : ArrayBufferView)
    {
        switch textureResources.get(_frame.page)
        {
            case null:
                //
            case glObject:
                final src = cpp.Pointer.arrayElem(_data.buffer.getData(), _data.byteOffset);

                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, glObject);
                glTexSubImage2D(
                    GL_TEXTURE_2D,
                    0,
                    _frame.x,
                    _frame.y,
                    _frame.width,
                    _frame.height,
                    GL_RGBA,
                    GL_UNSIGNED_BYTE,
                    cast src.ptr);
        }
    }

	function createShader(_resource : ShaderResource)
    {
        final result = 0;
        final shader = switch Std.downcast(_resource, Ogl3Shader)
        {
            case null: throw new Exception('Shader resource is not Ogl3Shader');
            case v: v;
        }
        
        // Compile the vertex shader.
        final vertex = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertex, 1, shader.vertCode, shader.vertCode.length);
        glCompileShader(vertex);

        glGetShaderiv(vertex, GL_COMPILE_STATUS, result);
        if (result == 0)
        {
            throw new Exception('Failed to compile vertex shader : $result');
        }

        // Compile the fragment shader.
        final fragment = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragment, 1, shader.fragCode, shader.fragCode.length);
        glCompileShader(fragment);

        glGetShaderiv(fragment, GL_COMPILE_STATUS, result);
        if (result == 0)
        {
            throw new Exception('Failed to compile fragment shader : $result');
        }

        // Link the two together then remove the sources.
        final program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);

        glGetProgramiv(program, GL_LINK_STATUS, result);
        if (result == 0)
        {
            throw new Exception('Failed to link shader : $result');
        }

        glDeleteShader(vertex);
        glDeleteShader(fragment);

        // Create a representation of the shaders input.
        // TODO : This could probably be done by the OGL3 shader processor.

        var offset = 0;

        final layout = [];

        for (i in 0...shader.format.count)
        {
            final element = shader.format.get(i);
            final size    = getVertexInputFloatSize(element.type);
            final native  = new OGL3ShaderInputElement(element.location, size, offset);

            layout.push(native);

            offset += size * 4;
        }

        // Query the location of all combined texture and samplers.
        final combinedLocations = [ for (combined in shader.samplers) glGetUniformLocation(program, combined) ];

        // Query the location of all uniform blocks and store them.
        // Also setup the uniform index to binding relationship.
        final matrixBlock    = Lambda.find(shader.blocks.toArray(), b -> b.name == 'flurry_matrices');
        final matrixLocation = if (matrixBlock != null) matrixBlock.binding else -1;
        final blockNames     = [ for (block in shader.blocks) block.name ];
        final blockLocations = [ for (block in shader.blocks) {
            final idx = glGetUniformBlockIndex(program, block.name);

            glUniformBlockBinding(program, idx, block.binding);

            block.binding;
        } ];

        shaderResources.set(shader.id, new OGL3ShaderInformation(program, layout, offset, combinedLocations, blockLocations, matrixLocation, blockNames));
    }

	function deleteShader(_id : ResourceID)
    {
        switch shaderResources.get(_id)
        {
            case null:
                //
            case shader:
                glDeleteProgram(shader.program);

                shaderResources.remove(_id);
        }
    }

	function createTexture(_resource : PageResource)
    {
        final id = 0;
        glGenTextures(1, id);
        glBindTexture(GL_TEXTURE_2D, id);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _resource.width, _resource.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _resource.pixels);

        textureResources.set(_resource.id, id);
    }

	function deleteTexture(_id : ResourceID)
    {
        switch textureResources.get(_id)
        {
            case null:
                //
            case glObject:
                glDeleteTextures(1, glObject);

                textureResources.remove(_id);
        }
    }

    static function createBackBuffer(_width : Int, _height : Int)
    {
        // Create a texture for our backbuffer.
        final tex = 0;
        glGenTextures(1, tex);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);

        // Create a depth and stencil texture for our backbuffer.
        final rbo = 0;
        glGenRenderbuffers(1, rbo);
        glBindRenderbuffer(GL_RENDERBUFFER, rbo);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, _width, _height);

        // Create a framebuffer with the above colour, depth, and stencil texture attached.
        final fbo = 0;
        glGenFramebuffers(1, fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);

        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            throw new Exception('Backbuffer framebuffer is not complete');
        }

        return new OGL3SurfaceInformation(tex, rbo, fbo, _width, _height);
    }

    function getNextPipelineID()
    {
        for (i in 0...pipelines.length)
        {
            if (pipelines[i] == null)
            {
                return i;
            }
        }

        throw new Exception('Maximum number of pipelines met');
    }

    function getNextSurfaceID()
    {
        for (i in 0...surfaces.length)
        {
            if (surfaces[i] == null)
            {
                return i;
            }
        }

        throw new Exception('Maximum number of surfaces met');
    }

    function getVertexInputFloatSize(_type : VertexType)
    {
        return switch _type
        {
            case Vector2: 2;
            case Vector3: 3;
            case Vector4: 4;
        }
    }
}