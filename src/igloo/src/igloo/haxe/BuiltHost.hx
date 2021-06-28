package igloo.haxe;

import igloo.utils.GraphicsApi;

class BuiltHost
{
    public var gpu : GraphicsApi;

    public var entry : String;

    public function new(_gpu, _entry)
    {
        gpu   = _gpu;
        entry = _entry;
    }
}