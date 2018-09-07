package;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
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

    /**
     * Creates a binary packed parcel containing the assets found in a json file.
     * The json file contains the ID of the asset and the path to file the bytes data.
     * These assets are then loaded, serialized, and optionally compressed.
     * The resource system can then load these binary parcels instead of manually specifying the resources found in a parcel.
     * 
     * All path locations provided to this command or found in the json file should be absolute locations or relative to the parcel tool / current directory.
     * 
     * @param _jsonPath JSON file location.
     * @param _output   Created parcel location.
     * @param _compress If this parcel should be compressed.
     * @param _verbose  If debug information should be printed.
     */
    public static function createFromJson(_jsonPath : String, _output : String, _compress : Bool, _verbose : Bool)
    {
        var parcel : ParcelList = Json.parse(sys.io.File.getContent(_jsonPath));

        // Load and create resources for all the requested assets.
        // This chunck of asset loading and resource creation is basically identical to that found in the resource system.
        // Code could probably be shared.

        var resources = new Array<Resource>();

        var assets : Array<BytesInfo> = def(parcel.bytes, []);
        for (asset in assets)
        {
            resources.push(new BytesResource(asset.id, sys.io.File.getBytes(asset.id)));

            log('Bytes asset "${asset.id}" added', _verbose);
        }

        var assets : Array<TextInfo> = def(parcel.texts, []);
        for (asset in assets)
        {
            resources.push(new TextResource(asset.id, sys.io.File.getContent(asset.id)));

            log('Text asset "${asset.id}" added', _verbose);
        }

        var assets : Array<JSONInfo> = def(parcel.jsons, []);
        for (asset in assets)
        {
            resources.push(new JSONResource(asset.id, Json.parse(sys.io.File.getContent(asset.id))));

            log('JSON asset "${asset.id}" added', _verbose);
        }

        var assets : Array<ImageInfo> = def(parcel.images, []);
        for (asset in assets)
        {
            var bytes = sys.io.File.getBytes(asset.id);
            var info  = stb.Image.load_from_memory(bytes.getData(), bytes.length, 4);

            resources.push(new ImageResource(asset.id, info.w, info.h, info.bytes));

            log('Image asset "${asset.id}" added', _verbose);
        }

        var assets : Array<ShaderInfo> = def(parcel.shaders, []);
        for (asset in assets)
        {
            var layout = Json.parse(sys.io.File.getContent(asset.id));
            var sourceWebGL = asset.webgl == null ? null : { vertex : sys.io.File.getContent(asset.webgl.vertex), fragment : sys.io.File.getContent(asset.webgl.fragment) };
            var sourceGL45  = asset.gl45  == null ? null : { vertex : sys.io.File.getContent(asset.gl45.vertex) , fragment : sys.io.File.getContent(asset.gl45.fragment) };
            var sourceHLSL  = asset.hlsl  == null ? null : { vertex : sys.io.File.getContent(asset.hlsl.vertex) , fragment : sys.io.File.getContent(asset.hlsl.fragment) };

            resources.push(new ShaderResource(asset.id, layout, sourceWebGL, sourceGL45, sourceHLSL));

            log('Shader asset "${asset.id}" added', _verbose);
            log('   webgl : ${asset.webgl != null}', _verbose);
            log('   gl45  : ${asset.gl45  != null}', _verbose);
            log('   hlsl  : ${asset.hlsl  != null}', _verbose);
        }

        // Serialize the assets array and then optionally compress the bytes.
        // Haxe Compress.run compression is handled by zlib, 9 indicates optimise for size over speed.

        var serializer = new Serializer();
        serializer.serialize(resources);

        var arrayBytes = Bytes.ofString(serializer.toString());
        log('Assets array serialized to ${arrayBytes.length} bytes', _verbose);

        if (_compress)
        {
            arrayBytes = haxe.zip.Compress.run(arrayBytes, 9);
            log('Assets array compressed to ${arrayBytes.length} bytes', _verbose);
        }

        // The actual stored bytes is a ParcelData struct.
        // It contains the resource array bytes and if they have been compressed.

        var parcelBytes : ParcelData = {
            compressed      : _compress,
            serializedArray : arrayBytes
        };

        var serializer = new Serializer();
        serializer.serialize(parcelBytes);

        // Write the final bytes to the specified file location.

        sys.io.File.saveBytes(_output, Bytes.ofString(serializer.toString()));
        log('Parcel written to $_output', _verbose);
    }

    static inline function def(_value : Dynamic, _def : Dynamic) : Dynamic
    {
        return _value == null ? _def : _value;
    }

    static inline function log(_message : String, _verbose : Bool)
    {
        if (_verbose)
        {
            trace(_message);
        }
    }
}
