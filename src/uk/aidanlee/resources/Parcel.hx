package uk.aidanlee.resources;

import snow.api.Debug.def;
import uk.aidanlee.resources.ResourceSystem;
import uk.aidanlee.utils.Hash;

typedef ResourceInfo   = { id : String }
typedef BytesInfo      = ResourceInfo;
typedef TextInfo       = ResourceInfo;
typedef JSONInfo       = ResourceInfo;
typedef ImageInfo      = ResourceInfo;
typedef ShaderInfo     = {
    >ResourceInfo,

    ?webgl : {
        vertex   : String,
        fragment : String
    },

    ?gl45 : {
        vertex   : String,
        fragment : String
    },

    hlsl : {
        vertex   : String,
        fragment : String
    }
};

typedef ParcelList = {
    ?bytes   : Array<BytesInfo>,
    ?texts   : Array<TextInfo>,
    ?jsons   : Array<JSONInfo>,
    ?images  : Array<ImageInfo>,
    ?shaders : Array<ShaderInfo>
}

class Parcel
{
    public final id : String;

    public final list : ParcelList;

    public final onLoaded : Array<Resource>->Void;

    final system : ResourceSystem;

    public function new(_system : ResourceSystem, ?_name : String, ?_list : ParcelList, _resources : Array<Resource>->Void)
    {
        system   = _system;
        id       = def(_name, Hash.uniqueID());
        list     = def(_list, {});
        onLoaded = _resources;

        system.parcels.set(id, this);
    }

    public function load()
    {
        system.load(id);
    }

    public function free()
    {
        system.free(id);
    }
}
