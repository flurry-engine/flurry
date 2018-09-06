package;

import haxe.Json;
import haxe.Serializer;
import haxe.io.Path;
import haxe.io.Bytes;
import sys.FileSystem;
import haxe.macro.Context;
import haxe.macro.Expr;
import Resource;

typedef ResourceInfo   = { id : String }
typedef BytesInfo      = ResourceInfo;
typedef TextInfo       = ResourceInfo;
typedef JSONInfo       = ResourceInfo;
typedef ImageInfo      = ResourceInfo;
typedef ShaderInfo     = {
    >ResourceInfo,

    var ?webgl : {
        vertex   : String,
        fragment : String
    };

    var ?gl45 : {
        vertex   : String,
        fragment : String
    };

    var ?hlsl : {
        vertex   : String,
        fragment : String
    };
};

typedef ParcelList = {
    var ?bytes   : Array<BytesInfo>;
    var ?texts   : Array<TextInfo>;
    var ?jsons   : Array<JSONInfo>;
    var ?images  : Array<ImageInfo>;
    var ?shaders : Array<ShaderInfo>;
}

typedef ParcelData = {
    var compressed : Bool;
    var serializedArray : Bytes;
}

class Parcel
{
    public static function createFromDirectory(_directory : String, _output : String, _compress : Bool, _ignoreHidden : Bool, _verbose : Bool) : Bool
    {
        for (item in FileSystem.readDirectory(_directory))
        {
            // If a file system item begins with a . then it is hidden e.g. .gitignore.
            // Ignore these items if the user has specified.
            if (_ignoreHidden && item.charAt(0) == '.')
            {
                continue;
            }
        }

        return false;
    }

    public static function createFromJson(_jsonPath : String, _output : String, _compress : Bool, _verbose : Bool) : Bool
    {
        var parcel : ParcelList = Json.parse(sys.io.File.getContent(_jsonPath));

        // Load and create resources for all the requested assets.
        var resources = new Array<Resource>();

        var assets : Array<BytesInfo> = def(parcel.bytes, []);
        for (asset in assets)
        {
            resources.push(new BytesResource(asset.id, sys.io.File.getBytes(asset.id)));
        }

        var assets : Array<TextInfo> = def(parcel.texts, []);
        for (asset in assets)
        {
            resources.push(new TextResource(asset.id, sys.io.File.getContent(asset.id)));
        }

        var assets : Array<JSONInfo> = def(parcel.jsons, []);
        for (asset in assets)
        {
            resources.push(new JSONResource(asset.id, Json.parse(sys.io.File.getContent(asset.id))));
        }

        var assets : Array<ImageInfo> = def(parcel.images, []);
        for (asset in assets)
        {
            var bytes = sys.io.File.getBytes(asset.id);
            var info  = stb.Image.load_from_memory(bytes.getData(), bytes.length, 4);

            resources.push(new ImageResource(asset.id, info.w, info.h, info.bytes));
        }

        var assets : Array<ShaderInfo> = def(parcel.shaders, []);
        for (asset in assets)
        {
            var layout = Json.parse(sys.io.File.getContent(asset.id));
            var sourceWebGL = asset.webgl == null ? null : { vertex : sys.io.File.getContent(asset.webgl.vertex), fragment : sys.io.File.getContent(asset.webgl.fragment) };
            var sourceGL45  = asset.gl45  == null ? null : { vertex : sys.io.File.getContent(asset.gl45.vertex) , fragment : sys.io.File.getContent(asset.gl45.fragment) };
            var sourceHLSL  = asset.hlsl  == null ? null : { vertex : sys.io.File.getContent(asset.hlsl.vertex) , fragment : sys.io.File.getContent(asset.hlsl.fragment) };

            resources.push(new ShaderResource(asset.id, layout, sourceWebGL, sourceGL45, sourceHLSL));
        }

        // Serialize the array of assets
        var serializer = new Serializer();
        serializer.serialize(resources);

        var arrayBytes = Bytes.ofString(serializer.toString());

        // Compress them if requested
        if (_compress)
        {
            arrayBytes = haxe.zip.Compress.run(arrayBytes, 9);
        }

        // Serialize a struct with the array bytes and a compressed flag.
        var parcelBytes : ParcelData = {
            compressed      : _compress,
            serializedArray : arrayBytes
        };

        var serializer = new Serializer();
        serializer.serialize(parcelBytes);

        sys.io.File.saveBytes(_output, Bytes.ofString(serializer.toString()));

        return false;
    }

    public static function unpack(_directory : String) : Bool
    {
        return false;
    }

    static function def(_value : Dynamic, _def : Dynamic) : Dynamic
    {
        return _value == null ? _def : _value;
    }
}
