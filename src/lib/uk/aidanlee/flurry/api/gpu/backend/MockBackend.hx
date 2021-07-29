package uk.aidanlee.flurry.api.gpu.backend;

import uk.aidanlee.flurry.api.resources.loaders.DesktopShaderLoader.Ogl3Shader;
import uk.aidanlee.flurry.api.resources.builtin.PageResource;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
import haxe.io.BytesData;
import haxe.Exception;
import hxrx.ISubscription;
import hxrx.observer.Observer;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;

class MockBackend extends Renderer
{
    final resourceEvents : ResourceEvents;

    final commands : Array<DrawCommand>;

    final textures : Map<ResourceID, Int>;

    final shaders : Map<ResourceID, Int>;

    final resourceCreatedSubscription : ISubscription;

    final resourceRemovedSubscription : ISubscription;

    public function new(_events : ResourceEvents)
    {
        resourceEvents = _events;
        commands       = [];
        textures       = [];
        shaders        = [];

        resourceCreatedSubscription = resourceEvents.created.subscribe(new Observer(onResourceCreated, null, null));
        resourceRemovedSubscription = resourceEvents.removed.subscribe(new Observer(onResourceRemoved, null, null));
    }

    public function queue(_command : DrawCommand)
    {
        commands.push(_command);
    }

    public function submit()
    {
        for (command in commands)
        {
            checkCommand(command);
        }

        commands.resize(0);
    }

    public function cleanup()
    {
        resourceCreatedSubscription.unsubscribe();
        resourceRemovedSubscription.unsubscribe();
    }

    public function uploadTexture(_frame : PageFrameResource, _data : BytesData)
    {
        if (!textures.exists(_frame.page))
        {
            throw new TextureNotFoundException();
        }
    }

    function checkCommand(_command : DrawCommand)
    {
        switch _command.target
        {
            case Backbuffer:
            case Texture(_image):
                if (textures.exists(_image))
                {
                    throw new FramebufferNotFoundException();
                }
        }

        if (!shaders.exists(_command.shader))
        {
            throw new ShaderNotFoundException();
        }

        for (texture in _command.textures)
        {
            if (!textures.exists(texture))
            {
                throw new TextureNotFoundException();
            }
        }
    }

    function onResourceCreated(_resource : Resource)
    {
        if (_resource is PageResource)
        {
            textures.set(_resource.id, _resource.id);
        }
        else if (_resource is Ogl3Shader)
        {
            shaders.set(_resource.id, _resource.id);
        }
    }

    function onResourceRemoved(_resource : Resource)
    {
        if (_resource is PageResource)
        {
            textures.remove(_resource.id);
        }
        else if (_resource is Ogl3Shader)
        {
            shaders.remove(_resource.id);
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
