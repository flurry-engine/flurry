Build File Format

```json
{
    "app" : {
        "name"      : "ExecutableName",
        "author"   : "My Name",
        "output"    : "bin",
        "main"      : "Main",
        "codepaths" : [ "src" ],
        "backend"   : "Sdl"
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
                "id"       : "unique_id",
                "vertex"   : "shaders/vert.glsl",
                "fragment" : "shaders/frag.glsl"
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