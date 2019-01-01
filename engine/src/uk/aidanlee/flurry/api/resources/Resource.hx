package uk.aidanlee.flurry.api.resources;

import haxe.Json;
import haxe.io.BytesData;
import haxe.io.Bytes;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.gpu.backend.IRendererBackend.ShaderLayout;

typedef ShaderBackend = { vertex : String, fragment : String };

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

    public final webgl : ShaderBackend;

    public final gl45 : ShaderBackend;

    public final hlsl : ShaderBackend;

    public final uniforms : Uniforms;

    public function new(_id : String, _layout : ShaderLayout, _webgl : ShaderBackend = null, _gl45 : ShaderBackend = null, _hlsl : ShaderBackend = null)
    {
        super(_id);

        layout   = _layout;
        webgl    = _webgl;
        gl45     = _gl45;
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
