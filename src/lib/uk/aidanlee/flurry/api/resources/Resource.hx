package uk.aidanlee.flurry.api.resources;

import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.maths.Hash;
import haxe.io.BytesData;
import hxbit.Serializer;
import hxbit.Serializable;
import haxe.io.Bytes;

typedef ResourceID = Int;

enum abstract ShaderType(Int)
{
    var Matrix4;
    var Vector2;
    var Vector3;
    var Vector4;
    var Texture2D;
    var Sampler;
    var TFloat;
}

enum ResourceType
{
    Bytes;
    Text;
    Font;
    Image;
    ImageFrame;
    Sprite;
    Shader;
}

enum PixelFormat
{
    RGBAUNorm;
    BGRAUNorm;
}

@:nullSafety(Off) class Resource implements Serializable
{
    @:s public var type (default, null) : ResourceType;

    @:s public var name (default, null) : String;

    @:s public var id (default, null) : Int;

    public function new(_type : ResourceType, _name : String)
    {
        type = _type;
        name = _name;
        id   = Hash.hash(name);
    }
}

@:nullSafety(Off) class BytesResource extends Resource
{
    @:s public var bytes (default, null) : Bytes;

    public function new(_name : String, _bytes : Bytes)
    {
        super(Bytes, _name);

        bytes = _bytes;
    }
}

@:nullSafety(Off) class TextResource extends Resource
{
    @:s public var content (default, null) : String;

    public function new(_name : String, _content : String)
    {
        super(Text, _name);

        content = _content;
    }
}

@:nullSafety(Off) class ImageResource extends Resource
{
    /**
     * Pixel width of this texture.
     */
    @:s public var width (default, null) : Int;

    /**
     * Pixel height of this texture.
     */
    @:s public var height (default, null) : Int;

    /**
     * The format the pixel data is in.
     */
    @:s public var format (default, null) : PixelFormat;

    /**
     * Pixel data of this texture.
     * Modifying this does not modify the actual images data.
     */
    public var pixels (default, null) : BytesData;

    public function new(_name : String, _width : Int, _height : Int, _format : PixelFormat, _pixels : BytesData)
    {
        super(Image, _name);

        width  = _width;
        height = _height;
        format = _format;
        pixels = _pixels;
    }
}

@:nullSafety(Off) class ImageFrameResource extends Resource
{
    /**
     * Unique ID of the `ImageResource` all of the frames are contained within.
     */
    @:s public var image (default, null) : ResourceID;

    @:s public var x (default, null) : Int;

    @:s public var y (default, null) : Int;

    @:s public var width (default, null) : Int;

    @:s public var height (default, null) : Int;

    @:s public var u1 (default, null) : Float;

    @:s public var v1 (default, null) : Float;

    @:s public var u2 (default, null) : Float;

    @:s public var v2 (default, null) : Float;

    public function new(_name : String, _image : String, _x : Int, _y : Int, _width : Int, _height : Int, _u1 : Float, _v1 : Float, _u2 : Float, _v2 : Float)
    {
        super(ImageFrame, _name);

        image  = Hash.hash(_image);
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;
        u1     = _u1;
        v1     = _v1;
        u2     = _u2;
        v2     = _v2;
    }
}

@:nullSafety(Off) class SpriteResource extends ImageFrameResource
{
    @:s public var animations (default, null) : Map<String, Array<SpriteFrameResource>>;

    public function new(_name : String, _image : String, _x : Int, _y : Int, _width : Int, _height : Int, _u1 : Float, _v1 : Float, _u2 : Float, _v2 : Float, _animations : Map<String, Array<SpriteFrameResource>>)
    {
        super(_name, _image, _x, _y, _width, _height, _u1, _v1, _u2, _v2);

        type       = Sprite;
        animations = _animations;
    }
}

@:nullSafety(Off) class SpriteFrameResource implements Serializable
{
    /**
     * Pixel width of this sprite frame.
     */
    @:s public var width (default, null) : Int;

    /**
     * Pixel height of this sprite frame.
     */
    @:s public var height (default, null) : Int;

    /**
     * Base length in miliseconds this frame will be displayed for.
     */
    @:s public var duration (default, null) : Int;

    @:s public var u1 (default, null) : Float;

    @:s public var v1 (default, null) : Float;

    @:s public var u2 (default, null) : Float;

    @:s public var v2 (default, null) : Float;

    public function new(_width : Int, _height : Int, _duration : Int, _u1 : Float, _v1 : Float, _u2 : Float, _v2 : Float)
    {
        width    = _width;
        height   = _height;
        duration = _duration;
        u1       = _u1;
        v1       = _v1;
        u2       = _u2;
        v2       = _v2;
    }
}

@:nullSafety(Off) class FontResource extends ImageFrameResource
{
    @:s public var characters (default, null) : Map<Int, Character>;

    @:s public var lineHeight (default, null) : Float;

    public function new(_name : String, _image : String, _characters : Map<Int, Character>, _lineHeight : Float, _x : Int, _y : Int, _width : Int, _height : Int, _u1 : Float, _v1 : Float, _u2 : Float, _v2 : Float)
    {
        super(_name, _image, _x, _y, _width, _height, _u1, _v1, _u2, _v2);

        type       = Font;
        characters = _characters;
        lineHeight = _lineHeight;
    }
}

@:nullSafety(Off) class Character implements Serializable
{
    @:s public var x (default, null) : Float;

    @:s public var y (default, null) : Float;

    @:s public var width (default, null) : Float;

    @:s public var height (default, null) : Float;

    @:s public var xAdvance (default, null) : Float;

    @:s public var u1 (default, null) : Float;

    @:s public var v1 (default, null) : Float;

    @:s public var u2 (default, null) : Float;

    @:s public var v2 (default, null) : Float;

    public function new(
        _x : Float,
        _y : Float,
        _width : Float,
        _height : Float,
        _xAdvance : Float,
        _u1 : Float,
        _v1 : Float,
        _u2 : Float,
        _v2 : Float)
    {
        x        = _x;
        y        = _y;
        width    = _width;
        height   = _height;
        xAdvance = _xAdvance;
        u1       = _u1;
        v1       = _v1;
        u2       = _u2;
        v2       = _v2;
    }
}

@:nullSafety(Off) class ShaderResource extends Resource
{
    @:s public var vertSource (default, null) : Bytes;

    @:s public var fragSource (default, null) : Bytes;

    @:s public var vertInfo (default, null) : ShaderVertInfo;

    @:s public var fragInfo (default, null) : ShaderFragInfo;

    public function new(_name, _vertSource, _fragSource, _vertInfo, _fragInfo)
    {
        super(Shader, _name);

        vertSource = _vertSource;
        fragSource = _fragSource;
        vertInfo   = _vertInfo;
        fragInfo   = _fragInfo;
    }
}

@:nullSafety(Off) class ShaderVertInfo implements Serializable
{
    @:s public var input (default, null) : ReadOnlyArray<ShaderInput>;

    @:s public var blocks (default, null) : ReadOnlyArray<ShaderBlock>;

    public function new(_input, _blocks)
    {
        input  = _input;
        blocks = _blocks;
    }
}

@:nullSafety(Off) class ShaderFragInfo implements Serializable
{
    @:s public var textures (default, null) : ReadOnlyArray<ShaderInput>;

    @:s public var samplers (default, null) : ReadOnlyArray<ShaderInput>;

    @:s public var blocks (default, null) : ReadOnlyArray<ShaderBlock>;

    public function new(_textures, _samplers, _blocks)
    {
        textures = _textures;
        samplers = _samplers;
        blocks   = _blocks;
    }
}

@:nullSafety(Off) class ShaderInput implements Serializable
{
    @:s public var name (default, null) : String;

    @:s public var type (default, null) : ShaderType;

    @:s public var location (default, null) : Int;

    public function new(_name, _type, _location)
    {
        name     = _name;
        type     = _type;
        location = _location;
    }
}

@:nullSafety(Off) class ShaderBlock implements Serializable
{
    @:s public var name (default, null) : String;

    @:s public var size (default, null) : Int;

    @:s public var binding (default, null) : Int;

    @:s public var members (default, null) : ReadOnlyArray<ShaderInput>;

    public function new(_name, _size, _binding, _members)
    {
        name    = _name;
        size    = _size;
        binding = _binding;
        members = _members;
    }
}
