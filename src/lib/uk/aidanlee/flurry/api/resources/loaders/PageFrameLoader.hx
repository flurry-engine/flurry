package uk.aidanlee.flurry.api.resources.loaders;

import haxe.io.Input;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;

class PageFrameLoader extends ResourceReader
{
    override function ids()
    {
        return [ 'png', 'jpg', 'jpeg', 'tga', 'bmp', 'atlas' ];
    }

    override function read(_input : Input)
    {
        final id   = _input.readInt32();
        final page = _input.readInt32();

        final x = _input.readInt32();
        final y = _input.readInt32();
        final w = _input.readInt32();
        final h = _input.readInt32();

        final u1 = _input.readFloat();
        final v1 = _input.readFloat();
        final u2 = _input.readFloat();
        final v2 = _input.readFloat();

        return new PageFrameResource(new ResourceID(id), new ResourceID(page), x, y, w, h, u1, v1, u2, v2);
    }
}