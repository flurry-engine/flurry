package uk.aidanlee.flurry.api.resources;

import haxe.Json;
import haxe.io.BytesData;
import haxe.io.Bytes;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Matrix;

enum ShaderType
{
    Matrix4;
    Vector4;
    Int;
}

typedef ShaderBackend = { vertex : String, fragment : String };

typedef ShaderLayout = { textures : Array<String>, blocks : Array<ShaderBlock> };

typedef ShaderBlock = { name : String, vals : Array<{ name : String, type : String }> };

class Resource
{
    public final id : String;

    public function new(_id : String)
    {
        id = _id;
    }
}

class BytesResource extends Resource
{
    public final bytes : Bytes;

    public function new(_id : String, _bytes : Bytes)
    {
        super(_id);

        bytes = _bytes;
    }
}

class TextResource extends Resource
{
    public final content : String;

    public function new(_id : String, _content : String)
    {
        super(_id);

        content = _content;
    }
}

class JSONResource extends Resource
{
    public final json : Json;

    public function new(_id : String, _json : Json)
    {
        super(_id);

        json = _json;
    }
}

class ImageResource extends Resource
{
    public final width : Int;

    public final height : Int;

    public final pixels : BytesData;

    public function new(_id : String, _width : Int, _height : Int, _pixels : BytesData)
    {
        super(_id);

        width  = _width;
        height = _height;
        pixels = _pixels;
    }
}

class ShaderResource extends Resource
{
    public final layout : ShaderLayout;

    public final ogl3 : ShaderBackend;

    public final ogl4 : ShaderBackend;

    public final hlsl : ShaderBackend;

    public final uniforms : Uniforms;

    public function new(_id : String, _layout : ShaderLayout, _ogl3 : ShaderBackend = null, _ogl4 : ShaderBackend = null, _hlsl : ShaderBackend = null)
    {
        super(_id);

        layout   = _layout;
        ogl3     = _ogl3;
        ogl4     = _ogl4;
        hlsl     = _hlsl;
        uniforms = new Uniforms();
    }
}

private class Uniforms
{
    public final int : Map<String, Int>;

    public final vector4 : Map<String, Vector>;

    public final matrix4 : Map<String, Matrix>;

    public function new()
    {
        int     = new Map();
        vector4 = new Map();
        matrix4 = new Map();
    }
}
