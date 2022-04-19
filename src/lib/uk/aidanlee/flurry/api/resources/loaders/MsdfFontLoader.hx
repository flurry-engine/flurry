package uk.aidanlee.flurry.api.resources.loaders;

import uk.aidanlee.flurry.api.resources.ResourceID;
import uk.aidanlee.flurry.api.resources.builtin.FontResource;
import haxe.io.Input;

class MsdfFontLoader extends ResourceReader
{
    override function ids()
    {
        return [ 'ttf', 'otf' ];
    }

    override function read(_input : Input)
    {
        final id         = _input.readInt32();
        final page       = _input.readInt32();
        final lineHeight = _input.readFloat();
        final glyphCount = _input.readInt32();
        final glyphs     = new Map();

        for (_ in 0...glyphCount)
        {
            final unicode = _input.readInt32();
            final advance = _input.readFloat();

            final pLeft   = _input.readFloat();
            final pTop    = _input.readFloat();
            final pRight  = _input.readFloat();
            final pBottom = _input.readFloat();

            final u1 = _input.readFloat();
            final v1 = _input.readFloat();
            final u2 = _input.readFloat();
            final v2 = _input.readFloat();

            glyphs[unicode] = new FontGlyph(advance, pLeft, pTop, pRight, pBottom, u1, v1, u2, v2);
        }

        return new FontResource(new ResourceID(id), new ResourceID(page), lineHeight, glyphs);
    }
}