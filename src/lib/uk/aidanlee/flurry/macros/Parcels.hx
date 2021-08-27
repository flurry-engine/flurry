package uk.aidanlee.flurry.macros;

import haxe.Exception;
import haxe.macro.Expr.TypeDefinition;
import hx.files.Path;
import haxe.macro.Context;
import sys.io.File;
import haxe.Json;

using hx.strings.Strings;

typedef PageMeta = {
    final id : Int;
}

typedef AssetMeta = {
    final name : String;
    final produced : Array<ProducedMeta>;
}

typedef ProducedMeta = {
    final name : String;
    final id : Int;
}

typedef ParcelMeta = {
    final pages : Array<PageMeta>;
    final assets : Array<AssetMeta>;
}

typedef ShaderBufferElement = {
    final size : Int;
    final stride : Int;
    final type : String;
    final name : String;
    final offset : Int;
}

typedef ShaderBuffer = {
    final name : String;
    final size : Int;
    final elements : Array<ShaderBufferElement>;
}

private var totalParcels   = 0;
private var totalResources = 0;

macro function loadParcelMeta(_name : String, _path : String)
{
    final path = Path.of(_path);

    // Create a class with static inline fields for all resources contained within the parcel.
    // Pages are not included in the fields.

    final meta  = (Json.parse(path.toFile().readAsString()) : ParcelMeta);
    final clazz = _name.toUpperCaseFirstChar();
    final built = macro class $clazz {}

    totalResources += meta.pages.length;

    for (asset in meta.assets)
    {
        totalResources += asset.produced.length;

        for (produced in asset.produced)
        {
            built.fields.push({
                name: produced.name,
                pos : Context.currentPos(),
                kind: FVar(macro : uk.aidanlee.flurry.api.resources.ResourceID, macro new uk.aidanlee.flurry.api.resources.ResourceID($v{ produced.id })),
                access: [ APublic, AStatic, AFinal ]
            });
        }
    }

    built.pack = [ 'uk', 'aidanlee', 'flurry', 'api', 'resources', 'parcels' ];

    try
    {
        Context.getType('uk.aidanlee.flurry.api.resources.parcels.${ clazz }');

        // What should we do if the type is already defined?!
    }
    catch (e)
    {
        // not defined, so do so now.

        Context.defineType(built);
    }

    // See if there is any shader metadata we can read and generate abstracts for.

    final shaders = path.parent.joinAll([ _name, 'shader_buffers' ]).toDir().findFiles('*.json');

    for (shader in shaders)
    {
        final data = (Json.parse(shader.readAsString()) : Array<ShaderBuffer>);
        
        for (buffer in data)
        {
            final name = buffer.name.toUpperCaseFirstChar();
            final tstr = 'uk.aidanlee.flurry.api.gpu.shaders.uniforms.$name';
            final type : TypeDefinition = {
                name   : name,
                pack   : [ 'uk', 'aidanlee', 'flurry', 'api', 'gpu', 'shaders', 'uniforms' ],
                kind   : TDAbstract(macro : uk.aidanlee.flurry.api.gpu.geometry.UniformBlob, null, [macro : uk.aidanlee.flurry.api.gpu.geometry.UniformBlob]),
                pos    : Context.currentPos(),
                fields : [
                    {
                        name: 'new',
                        pos: Context.currentPos(),
                        access: [ APublic, AInline ],
                        kind: FFun({
                            args: [],
                            expr: macro {
                                this = new uk.aidanlee.flurry.api.gpu.geometry.UniformBlob($v{ buffer.name }, new haxe.io.ArrayBufferView($v{ buffer.size }));
                            }
                        })
                    }
                ]
            }

            final getCt = function(_type : String) return switch _type
            {
                case 'bool'            : macro : Bool;
                case 'int', 'uint'     : macro : Int;
                case 'float', 'double' : macro : Float;
                case 'vec2'            : macro : Vec2;
                case 'vec3'            : macro : Vec3;
                case 'vec4'            : macro : Vec4;
                case 'mat2'            : macro : Mat2;
                case 'mat3'            : macro : Mat3;
                case 'mat4'            : macro : Mat4;
                case other             : throw new Exception('Unsupported glsl type $other');
            };
            final getTypedArray = function(_type : String) return switch _type
            {
                case 'bool', 'int', 'uint': macro final writer = haxe.io.Int32Array.fromData(this.buffer.getData());
                case 'double': macro final writer = haxe.io.Float64Array.fromData(this.buffer.getData());
                case _: macro final writer = haxe.io.Float32Array.fromData(this.buffer.getData());
            }
            final getTypeWriter = function(_type : String, _offset : Int) return switch _type
            {
                case 'int', 'uint', 'float':
                    macro writer[$v{ Std.int(_offset / 4) }] = _v;
                case 'bool':
                    macro writer[$v{ Std.int(_offset / 4) }] = if (_v) 1 else 0;
                case 'double':
                    macro writer[$v{ Std.int(_offset / 8) }] = _v;
                case 'vec2':
                    macro {
                        final data = (_v : Vec2.Vec2Data);
                        final base = $v{ Std.int(_offset / 4) };
                        writer[base + 0] = data.x;
                        writer[base + 1] = data.y;

                        return _v;
                    }
                case 'vec3':
                    macro {
                        final data = (_v : Vec3.Vec3Data);
                        final base = $v{ Std.int(_offset / 4) };
                        writer[base + 0] = data.x;
                        writer[base + 1] = data.y;
                        writer[base + 2] = data.z;

                        return _v;
                    }
                case 'vec4':
                    macro {
                        final data = (_v : Vec4.Vec4Data);
                        final base = $v{ Std.int(_offset / 4) };
                        writer[base + 0] = data.x;
                        writer[base + 1] = data.y;
                        writer[base + 2] = data.z;
                        writer[base + 3] = data.w;

                        return _v;
                    }
                case other:
                    throw new Exception('unsupported glsl type $other');
            }

            for (element in buffer.elements)
            {
                switch element.size
                {
                    case 0:
                        final ct = getCt(element.type);

                        type.fields.push({
                            name   : element.name,
                            pos    : Context.currentPos(),
                            access : [ APublic ],
                            kind   : FProp('never', 'set', ct)
                        });
                        type.fields.push({
                            name   : 'set_${ element.name }',
                            pos    : Context.currentPos(),
                            access : [ APublic, AInline ],
                            kind   : FFun({
                                args : [ { name: '_v', type: ct } ],
                                ret  : ct,
                                expr : macro {
                                    $e{ getTypedArray(element.type) }
                                    $e{ getTypeWriter(element.type, element.offset) }
                                }
                            })
                        });
                    case size:
                        //
                }
            }

            try
            {
                Context.getType(tstr);
        
                // What should we do if the type is already defined?!
            }
            catch (e)
            {
                // not defined, so do so now.
        
                Context.defineType(type);
            }
        }
    }

    return macro null;
}

macro function getTotalResourceCount()
{
    return macro $v{ totalResources };
}