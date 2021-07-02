package uk.aidanlee.flurry.api.resources.builtin;

import haxe.io.BytesData;

class DataBlob
{
    public final name : String;

    public final data : BytesData;

    public function new(_name, _data)
    {
        name = _name;
        data = _data;
    }
}