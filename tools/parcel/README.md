# Parcel Tool

The parcel tool allows you to create compressed serialised resources at compile time to reduce your asset sizes. JSON files are used to define what assets should be serialised into each parcel.

## Usage
`./parcel-tool -from-json assets.json -output assets.parcel --compress --verbose`

## JSON Format

The following is an example of the JSON format. It is almost identical to manually adding resource locations to a parcel in code.

```
{
    "images" : [
        { "id" : "haxe", "path : "assets/images/haxe.png" },
        { "id" : "assets/images/logo.png" }
    ],
    "shaders" : [
        {
            "id"   : "std-shader-textured",
            "path" : "assets/shaders/textured.json",
            "gl45" : {
                "vertex"   : "assets/shaders/gl45/textured.vert",
                "fragment" : "assets/shaders/gl45/textured.frag"
            },
            "webgl" : {
                "vertex"   : "assets/shaders/webgl/textured.vert",
                "fragment" : "assets/shaders/webgl/textured.frag"
            },
            "hlsl" : {
                "vertex"   : "assets/shaders/hlsl/textured.hlsl",
                "fragment" : "assets/shaders/hlsl/textured.hlsl"
            }
        }
    ]
}
```

## Options

- `--compress` Apply zlib compression to the parcel
- `--verbose` Print information about each resource added to the parcel
