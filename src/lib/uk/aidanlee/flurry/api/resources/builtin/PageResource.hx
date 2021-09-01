package uk.aidanlee.flurry.api.resources.builtin;

import haxe.io.Bytes;

class PageResource extends Resource
{
    public final width : Int;

    public final height : Int;

    public function new(_id, _width, _height)
    {
        super(_id);

        width  = _width;
        height = _height;
    }
}