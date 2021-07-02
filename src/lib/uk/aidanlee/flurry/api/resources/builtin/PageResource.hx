package uk.aidanlee.flurry.api.resources.builtin;

import haxe.io.Bytes;

class PageResource extends Resource
{
    public final width : Int;

    public final height : Int;

    public final pixels : Bytes;

    public function new(_name, _width, _height, _pixels)
    {
        super(_name);

        width  = _width;
        height = _height;
        pixels = _pixels;
    }
}