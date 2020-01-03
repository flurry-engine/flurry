package uk.aidanlee.flurry.api.resources;

import uk.aidanlee.flurry.api.resources.Resource.ShaderType;

using Safety;

enum ParcelType
{
    Definition(_name : String, _definition : ParcelList);
    PrePackaged(_name : String);
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
