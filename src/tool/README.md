Build File Format

```json
{
    "app" : {
        "name"      : "ExecutableName",
        "author"   : "My Name",
        "output"    : "bin",
        "main"      : "Main",
        "codepaths" : [ "src" ],
        "backend"   : "Snow"
    },
    "meta" : {
        "name"    : "My Project",
        "author"  : "Aidan Lee",
        "version" : "1.0.0"
    },
    "build" : {
        "profile" : "Debug",
        "macros"  : [ "Safety.safeNavigation('some.package')" ],
        "defines" : [
            { "def" : "some_define" },
            { "def" : "some_other_define", "value" : "specific_value" }
        ],
        "dependencies" : [
            { "lib" : "some_lib" },
            { "lib" : "some_other_lib", "version" : "1.2.0" }
        ]
    },
    "parcels" : [ "assets/assets_bundle.json", "assets/another_bundle.json" ]
}
```

Assets File Format

```json
{
    "assets" : {
        "bytes" : [
            { "id" : "unique_id", "path" : "path/to/file.dat" }
        ],
        "texts" : [
            { "id" : "unique_id", "path" : "path/to/file.txt" }
        ],
        "fonts" : [
            { "id" : "unique_id", "path" : "path/to/font.ttf" }
        ],
        "images" : [
            { "id" : "unique_id", "path" : "path/to/file.png" }
        ],
        "sheets" : [
            { "id" : "unique_id", "path" : "path/to/file.atlas" }
        ],
        "shaders" : [
            {
                "id" : "unique_id",
                "path" : "definition.json",
                "ogl3" : { "vertex" : "ogl3/vert.glsl", "fragment" : "ogl3/frag.glsl", "compiled" : false },
                "ogl4" : { "vertex" : "ogl4/vert.glsl", "fragment" : "ogl4/frag.glsl", "compiled" : false },
                "hlsl" : { "vertex" : "hlsl/vert.hlsl", "fragment" : "hlsl/frag.hlsl", "compiled" : false }
            }
        ]
    },
    "parcels" : [
        {
            "name"    : "",
            "depends" : [ "" ],
            "bytes" : [ "unique_id" ],
            "texts" : [ "unique_id" ],
            "fonts" : [ "unique_id" ],
            "images" : [ "unique_id" ],
            "sheets" : [ "unique_id" ],
            "shaders" : [ "unique_id" ],
        }
    ]
}
```

Shader Definition File Format

```json
{
    "textures" : [ "defaultTexture" ],
    "blocks"   : [
        {
            "name"    : "flurry_matrices",
            "binding" : 0,
            "values"  : [
                { "type" : "Matrix4", "name" : "projection" },
                { "type" : "Matrix4", "name" : "view" },
                { "type" : "Matrix4", "name" : "model" }
            ]
        },
        {
            "name"    : "custom_block",
            "binding" : 1,
            "values"  : [
                { "type" : "Vector4", "name" : "some_vector" }
            ]
        }
    ]
}
```