package parcel;

import uk.aidanlee.flurry.api.resources.Resource.ShaderType;

typedef JsonResource = {
    var id : String;
    var path : String;
}

typedef JsonShaderValue = {
    var type : ShaderType;
    var name : String;
}

typedef JsonShaderBlock = {
    var name : String;
    var binding : Int;
    var values : Array<JsonShaderValue>;
}

typedef JsonShaderDefinition = {
    var textures : Array<String>;
    var blocks : Array<JsonShaderBlock>;
}

typedef JsonShaderSource = {
    var vertex : String;
    var fragment : String;
    var compiled : Bool;
}

typedef JsonShaderResource = JsonResource & {
    var ?ogl3 : JsonShaderSource;
    var ?ogl4 : JsonShaderSource;
    var ?hlsl : JsonShaderSource;
}

typedef JsonParcel = {
    var name : String;
    var depends : Array<String>;
    var ?bytes : Array<String>;
    var ?texts : Array<String>;
    var ?fonts : Array<String>;
    var ?images : Array<String>;
    var ?sheets : Array<String>;
    var ?sprites : Array<String>;
    var ?shaders : Array<String>;
}

typedef JsonAssets = {
    var bytes : Array<JsonResource>;
    var texts : Array<JsonResource>;
    var fonts : Array<JsonResource>;
    var images : Array<JsonResource>;
    var sheets : Array<JsonResource>;
    var sprites : Array<JsonResource>;
    var shaders : Array<JsonShaderResource>;
}

typedef JsonDefinition = {
    var assets : JsonAssets;
    var parcels : Array<JsonParcel>;
}

typedef JsonFontAtlas = {
    var type : String;
    var distanceRange : Int;
    var size : Int;
    var width : Int;
    var height : Int;
    var yOrigin : String;
}

typedef JsonFontMetrics = {
    var lineHeight : Float;
    var ascender : Float;
    var descender : Float;
    var underlineY : Float;
    var underlineThickness : Float;
}

typedef JsonFontGlyph = {
    var unicode : Int;
    var advance : Float;
    var ?planeBounds : {
        var left : Float;
        var bottom : Float;
        var right : Float;
        var top : Float;
    }
    var ?atlasBounds : {
        var left : Float;
        var bottom : Float;
        var right : Float;
        var top : Float;
    }
}

typedef JsonFontDefinition = {
    var atlas : JsonFontAtlas;
    var metrics : JsonFontMetrics;
    var glyphs : Array<JsonFontGlyph>;
    var kerning : Array<Dynamic>;
}

typedef JsonRectangle = {
    var x : Int;
    var y : Int;
    var w : Int;
    var h : Int;
}

typedef JsonSize = {
    var w : Int;
    var h : Int;
}

typedef JsonSpriteFrame = {
    var filename : String;
    var frame : JsonRectangle;
    var rotated : Bool;
    var trimmed : Bool;
    var spriteSourceSize : JsonRectangle;
    var sourceSize : JsonSize;
    var duration : Int;
}

typedef JsonSpriteTag = {
    var name : String;
    var from : Int;
    var to : Int;
    var direction : String;
}

typedef JsonSpriteMeta = {
    var app : String;
    var version : String;
    var image : String;
    var format : String;
    var size : JsonSize;
    var scale : String;
    var frameTags : Array<JsonSpriteTag>;
}

typedef JsonSprite = {
    var frames : Array<JsonSpriteFrame>;
    var meta : JsonSpriteMeta;
}
