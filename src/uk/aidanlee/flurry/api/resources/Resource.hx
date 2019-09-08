package uk.aidanlee.flurry.api.resources;

import haxe.io.Bytes;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;

enum ShaderType
{
    Matrix4;
    Vector4;
    Int;
    Float;
}

enum ResourceType
{
    Bytes;
    Text;
    Image;
    Shader;
    Custom(_name : String);
}

class Resource
{
    public var type (default, null) : ResourceType;

    public var id (default, null) : String;

    public function new(_type : ResourceType, _id : String)
    {
        type = _type;
        id   = _id;
    }
}

class BytesResource extends Resource
{
    public var bytes (default, null) : Bytes;

    public function new(_id : String, _bytes : Bytes)
    {
        super(Bytes, _id);

        bytes = _bytes;
    }
}

class TextResource extends Resource
{
    public var content (default, null) : String;

    public function new(_id : String, _content : String)
    {
        super(Text, _id);

        content = _content;
    }
}

class ImageResource extends Resource
{
    public var width (default, null) : Int;

    public var height (default, null) : Int;

    public var pixels (default, null) : Bytes;

    public function new(_id : String, _width : Int, _height : Int, _pixels : Bytes)
    {
        super(Image, _id);

        width  = _width;
        height = _height;
        pixels = _pixels;
    }
}

class ShaderResource extends Resource
{
    public var layout (default, null) : ShaderLayout;

    public var ogl3 (default, null) : Null<ShaderSource>;

    public var ogl4 (default, null) : Null<ShaderSource>;

    public var hlsl (default, null) : Null<ShaderSource>;

    public var uniforms (default, null) : Uniforms = new Uniforms();

    public function new(_id : String, _layout : ShaderLayout, _ogl3 : Null<ShaderSource>, _ogl4 : Null<ShaderSource>, _hlsl : Null<ShaderSource>)
    {
        super(Shader, _id);

        layout   = _layout;
        ogl3     = _ogl3;
        ogl4     = _ogl4;
        hlsl     = _hlsl;
    }
}

class ShaderSource
{
    /**
     * If this shader has been compiled offline.
     */
    public var compiled (default, null) : Bool;

    /**
     * Shaders vertex stage data.
     */
    public var vertex (default, null) : Bytes;

    /**
     * Shaders fragment stage data.
     */
    public var fragment (default, null) : Bytes;

    public function new(_compiled : Bool, _vertex : Bytes, _fragment : Bytes)
    {
        compiled = _compiled;
        vertex   = _vertex;
        fragment = _fragment;
    }
}

class ShaderLayout
{
    /**
     * Name of all the textures used in the fragment shader.
     * Names only really matter in Ogl3 shaders, in others the strings location in the array is used as the binding location.
     * So positioning within this array does matter!
     */
    public var textures (default, null) : Array<String>;

    /**
     * All of the UBOs / SSBOs / CBuffers used in this shader.
     */
    public var blocks (default, null) : Array<ShaderBlock>;

    public function new(_textures : Array<String>, _blocks : Array<ShaderBlock>)
    {
        textures = _textures;
        blocks   = _blocks;
    }
}

class ShaderBlock
{
    /**
     * Name of this shader block.
     * A shader block named "defaultMatrices" must have 3 4x4 matrices inside it.
     */
    public var name (default, null) : String;

    /**
     * The location this buffer is bound to.
     * Is not used with the Ogl3 backend.
     */
    public var binding (default, null) : Int;

    /**
     * All of the values in this block.
     */
    public var values (default, null) : Array<ShaderValue>;

    public function new(_name : String, _binding : Int, _values : Array<ShaderValue>)
    {
        name    = _name;
        binding = _binding;
        values  = _values;
    }
}

class ShaderValue
{
    public var name (default, null) : String;

    public var type (default, null) : ShaderType;

    public function new(_name : String, _type : ShaderType)
    {
        name = _name;
        type = _type;
    }
}

class ParcelResource
{
    /**
     * Name of this parcel.
     */
    public var name (default, null) : String;

    /**
     * List of the IDs of all assets to be included in this parcel.
     */
    public var assets (default, null) : Array<Resource>;

    /**
     * List of parcel names this parcel depends on.
     */
    public var depends (default, null) : Array<String>;

    public function new(_name : String, _assets : Array<Resource>, _depends : Array<String>)
    {
        name    = _name;
        assets  = _assets;
        depends = _depends;
    }
}
