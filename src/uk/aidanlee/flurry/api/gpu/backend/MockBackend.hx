package uk.aidanlee.flurry.api.gpu.backend;

import haxe.Exception;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;

using Lambda;

class MockBackend implements IRendererBackend
{
    final resourceEvents : ResourceEvents;

    final commands : Array<GeometryDrawCommand>;

    final textures : Map<String, ImageResource>;

    final shaders : Map<String, ShaderResource>;

    public function new(_events : ResourceEvents)
    {
        resourceEvents = _events;
        commands       = [];
        textures       = [];
        shaders        = [];

        resourceEvents.created.add(onResourceCreated);
        resourceEvents.removed.add(onResourceRemoved);
    }

    public function preDraw()
    {
        commands.resize(0);
    }

    public function queue(_command : GeometryDrawCommand)
    {
        commands.push(_command);
    }

    public function submit()
    {
        for (command in commands)
        {
            checkCommand(command);
        }
    }

    public function postDraw()
    {
        //
    }

    public function resize(_width : Int, _height : Int)
    {
        //
    }

    public function cleanup()
    {
        //
    }

    function checkCommand(_command : DrawCommand)
    {
        switch _command.target
        {
            case Backbuffer:
            case Texture(_image):
                if (textures.exists(_image.id))
                {
                    throw new FramebufferNotFoundException();
                }
        }

        if (!shaders.exists(_command.shader.id))
        {
            throw new ShaderNotFoundException();
        }

        for (texture in _command.textures)
        {
            if (!textures.exists(texture.id))
            {
                throw new TextureNotFoundException();
            }
        }
    }

    function onResourceCreated(_resource : Resource)
    {
        switch _resource.type
        {
            case Image  : textures.set(_resource.id, cast _resource);
            case Shader : shaders.set(_resource.id, cast _resource);
            case _:
        }
    }

    function onResourceRemoved(_resource : Resource)
    {
        switch _resource.type
        {
            case Image  : textures.remove(_resource.id);
            case Shader : shaders.remove(_resource.id);
            case _:
        }
    }
}

class CommandAlreadyUploadedException extends Exception
{
    public function new()
    {
        super('Attempting to upload a command which has already been uploaded.');
    }
}

class CommandNotUploadedException extends Exception
{
    public function new()
    {
        super('Attempting to submit a command which has not been uploaded.');
    }
}

class FramebufferNotFoundException extends Exception
{
    public function new()
    {
        super('Attempting to draw to a framebuffer which does not exist.');
    }
}

class TextureNotFoundException extends Exception
{
    public function new()
    {
        super('Attempting to draw a texture which does not exist.');
    }
}

class ShaderNotFoundException extends Exception
{
    public function new()
    {
        super('Attempting to draw with a shader which does not exist.');
    }
}
