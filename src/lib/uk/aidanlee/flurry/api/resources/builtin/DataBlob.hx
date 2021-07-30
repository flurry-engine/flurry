package uk.aidanlee.flurry.api.resources.builtin;

import haxe.io.BytesData;

class DataBlob
{
    public final id : ResourceID;

    public final data : BytesData;

    public function new(_id, _data)
    {
        id   = _id;
        data = _data;
    }
}