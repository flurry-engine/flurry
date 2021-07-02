package uk.aidanlee.flurry.api.resources.loaders;

import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.resources.builtin.PageFrameResource;
import haxe.io.Input;

using uk.aidanlee.flurry.api.InputUtils;

class GdxSpriteSheetLoader extends ResourceReader
{
    override function ids()
    {
        return [ 'atlas' ];
    }

    override function read(_input : Input)
    {
        final atlasName  = _input.readPrefixedString();
        final frameCount = _input.readInt32();
        final frames     = new Array<Resource>();

        for (_ in 0...frameCount)
        {
            final pageName     = _input.readPrefixedString();
            final pageNameHash = Hash.hash(pageName);
            final sectionCount = _input.readInt32();

            for (_ in 0...sectionCount)
            {
                final name  = _input.readPrefixedString();
                final x     = _input.readInt32();
                final y     = _input.readInt32();
                final w     = _input.readInt32();
                final h     = _input.readInt32();
                final u1    = _input.readFloat();
                final v1    = _input.readFloat();
                final u2    = _input.readFloat();
                final v2    = _input.readFloat();
                final frame = new PageFrameResource(name, pageNameHash, x, y, w, h, u1, v1, u2, v2);

                frames.push(frame);
            }
        }

        return frames;
    }
}