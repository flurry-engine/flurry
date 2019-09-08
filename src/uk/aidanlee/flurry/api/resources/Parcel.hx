package uk.aidanlee.flurry.api.resources;

import uk.aidanlee.flurry.api.resources.Resource.ShaderType;

using Safety;

enum ParcelType
{
    Definition(_name : String, _definition : ParcelList);
    PrePackaged(_name : String);
}

class Parcel
{
    /**
     * The system this parcel belongs to.
     */
    final system : ResourceSystem;

    /**
     * Name of this parcel.
     * Is unique to the system it belongs to.
     */
    public final name : String;

    /**
     * All the resources this parcel will load.
     */
    public final type : ParcelType;

    /**
     * Callback to be called once the parcel has been loaded.
     * Resource array is all of the resources loaded by this parcel into the system.
     */
    public final onLoaded : Null<(_resources : Array<Resource>)->Void>;

    /**
     * Callback to be called when progress has been made loading this parcel.
     * Progress is a normalized value for how many of the parcels resources have been loaded.
     */
    public final onProgress : Null<(_progress : Float)->Void>;

    /**
     * Callback to be called if loading the parcel fails.
     * Message is the exception message thrown causing the parcel to fail loading.
     */
    public final onFailed : Null<(_message : String)->Void>;

    /**
     * Manually create a new parcel.
     * @param _system   System this parcel belongs to.
     * @param _onLoaded Function to call once the parcel has been loaded.
     * @param _name     Unique name for this parcel (defaults to a unique hash).
     * @param _list     List of resources to load with this parcel (defaults to empty parcel list).
     */
    public function new(
        _system : ResourceSystem,
        _name   : String,
        _type   : ParcelType,
        ?_onLoaded   : (_loaded : Array<Resource>)->Void,
        ?_onProgress : (_progress : Float)->Void,
        ?_onFailed   : (_error : String)->Void)
    {
        system     = _system;
        name       = _name;
        type       = _type;
        onLoaded   = _onLoaded;
        onProgress = _onProgress;
        onFailed   = _onFailed;
    }

    public function load()
    {
        system.load(this);
    }

    public function free()
    {
        system.free(this);
    }
}

@:structInit
class ParcelList
{
    public var bytes   : Array<BytesInfo>;
    public var texts   : Array<TextInfo>;
    public var images  : Array<ImageInfo>;
    public var shaders : Array<ShaderInfo>;

    public function new(
        bytes   : Null<Array<BytesInfo>> = null,
        texts   : Null<Array<TextInfo>> = null,
        images  : Null<Array<ImageInfo>> = null,
        shaders : Null<Array<ShaderInfo>> = null
    )
    {
        this.bytes   = bytes.or([]);
        this.texts   = texts.or([]);
        this.images  = images.or([]);
        this.shaders = shaders.or([]);
    }
}

@:structInit
class ResourceInfo
{
    public final id : String;

    public final path : String;

    public function new(id : String, path : String)
    {
        this.id   = id;
        this.path = path;
    }
}

typedef BytesInfo    = ResourceInfo;
typedef TextInfo     = ResourceInfo;
typedef ImageInfo    = ResourceInfo;

@:structInit
class ShaderInfo extends ResourceInfo
{
    public final ogl3 : Null<ShaderInfoSource>;

    public final ogl4 : Null<ShaderInfoSource>;

    public final hlsl : Null<ShaderInfoSource>;

    public function new(id : String, path : String, ogl3 : Null<ShaderInfoSource>, ogl4 : Null<ShaderInfoSource>, hlsl : Null<ShaderInfoSource>)
    {
        super(id, path);

        this.ogl3 = ogl3;
        this.ogl4 = ogl4;
        this.hlsl = hlsl;
    }
}

@:structInit
class ShaderInfoSource
{
    /**
     * Path to the vertex shader source file.
     */
    public final vertex : String;

    /**
     * Path to the fragment shader source file.
     */
    public final fragment : String;

    /**
     * If the shader should be compiled.
     * Only applies to parcels created by the build tool.
     */
    public final compiled : Bool;

    public function new(vertex : String, fragment : String, compiled : Bool)
    {
        this.vertex   = vertex;
        this.fragment = fragment;
        this.compiled = compiled;
    }
}

/**
 * We need this duplicate shader layout definition since the one in the
 * flurry resource pacakge extends hxbit serializable interface which messes
 * up json2object's parsing with the __uid variable in the interface.
 */

@:structInit
class ShaderInfoLayout
{
    public final textures : Array<String>;

    public final blocks : Array<ShaderInfoLayoutBlock>;

    public function new(textures : Array<String>, blocks : Array<ShaderInfoLayoutBlock>)
    {
        this.textures = textures;
        this.blocks   = blocks;
    }
}

@:structInit
class ShaderInfoLayoutBlock
{
    public final name : String;

    public final binding : Int;

    public final values : Array<ShaderInfoLayoutValue>;

    public function new(name : String, binding : Int, values : Array<ShaderInfoLayoutValue>)
    {
        this.name    = name;
        this.binding = binding;
        this.values  = values;
    }
}

@:structInit
class ShaderInfoLayoutValue
{
    public final type : ShaderType;

    public final name : String;

    public function new(type : ShaderType, name : String)
    {
        this.type = type;
        this.name = name;
    }
}
