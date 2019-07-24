package uk.aidanlee.flurry.api.gpu.backend;

import haxe.Exception;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.batcher.GeometryDrawCommand;

using Lambda;

class MockBackend implements IRendererBackend
{
    final resourceEvents : ResourceEvents;

    final commands : Array<Int>;

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

    public function uploadGeometryCommands(_commands : Array<GeometryDrawCommand>)
    {
        for (command in _commands)
        {
            checkCommand(command);

            if (!commands.has(command.id))
            {
                commands.push(command.id);
            }
            else
            {
                throw new CommandAlreadyUploadedException();
            }
        }
    }

    public function uploadBufferCommands(_commands : Array<BufferDrawCommand>)
    {
        for (command in _commands)
        {
            checkCommand(command);

            if (!commands.has(command.id))
            {
                commands.push(command.id);
            }
            else
            {
                throw new CommandAlreadyUploadedException();
            }
        }
    }

    public function submitCommands(_commands : Array<DrawCommand>, _recordStats : Bool = true)
    {
        for (command in _commands)
        {
            if (!commands.has(command.id))
            {
                throw new CommandNotUploadedException();
            }

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
        if (_command.target != null && !textures.exists(_command.target.id))
        {
            throw new FramebufferNotFoundException();
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

    function onResourceCreated(_event : ResourceEventCreated)
    {
        switch _event.type
        {
            case uk.aidanlee.flurry.api.resources.ImageResource:
                textures.set(_event.resource.id, cast _event.resource);
            case uk.aidanlee.flurry.api.resources.ShaderResource:
                shaders.set(_event.resource.id, cast _event.resource);
            case _:
                //
        }
    }

    function onResourceRemoved(_event : ResourceEventRemoved)
    {
        switch _event.type
        {
            case uk.aidanlee.flurry.api.resources.ImageResource:
                textures.remove(_event.resource.id);
            case uk.aidanlee.flurry.api.resources.ShaderResource:
                textures.remove(_event.resource.id);
            case _:
                //
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
