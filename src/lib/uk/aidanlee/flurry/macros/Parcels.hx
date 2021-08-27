package uk.aidanlee.flurry.macros;

import haxe.macro.Printer;
import haxe.Json;
import haxe.Exception;
import haxe.ds.Option;
import haxe.macro.Expr.TypeDefinition;
import haxe.macro.Context;
import hx.files.Path;

using hx.strings.Strings;

private typedef PageMeta = {
    final id : Int;
}

private typedef AssetMeta = {
    final name : String;
    final produced : Array<ProducedMeta>;
}

private typedef ProducedMeta = {
    final name : String;
    final id : Int;
}

private typedef ParcelMeta = {
    final pages : Array<PageMeta>;
    final assets : Array<AssetMeta>;
}

private typedef ShaderBufferElement = {
    final size : Int;
    final stride : Int;
    final type : String;
    final name : String;
    final offset : Int;
}

private typedef ShaderBuffer = {
    final name : String;
    final size : Int;
    final elements : Array<ShaderBufferElement>;
}

private var totalParcels   = 0;
private var totalResources = 0;

macro function getTotalResourceCount()
{
    return macro $v{ totalResources };
}

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

    final shaders  = path.parent.joinAll([ _name, 'shader_buffers' ]).toDir().findFiles('*.json');
    final uboTypes = [];

    for (shader in shaders)
    {
        final data = (Json.parse(shader.readAsString()) : Array<ShaderBuffer>);
        
        for (buffer in data)
        {
            final name = buffer.name.toUpperCaseFirstChar();
            final type : TypeDefinition = {
                name   : name,
                pack   : [],
                kind   : TDAbstract(macro : uk.aidanlee.flurry.api.gpu.shaders.UniformBlob, null, [macro : uk.aidanlee.flurry.api.gpu.shaders.UniformBlob]),
                pos    : Context.currentPos(),
                fields : [
                    {
                        name: 'new',
                        pos: Context.currentPos(),
                        access: [ APublic, AInline ],
                        kind: FFun({
                            args: [],
                            expr: macro {
                                this = new uk.aidanlee.flurry.api.gpu.shaders.UniformBlob($v{ buffer.name }, new haxe.io.ArrayBufferView($v{ buffer.size }));
                            }
                        })
                    }
                ]
            }

            for (element in buffer.elements)
            {
                switch glslTypeToComplexType(element.type)
                {
                    case Some(ct):
                        final alignedOffset = getAlignedOffset(element.type, element.offset);

                        switch element.size
                        {
                            case 0:       
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
                                        expr : macro return this.write($v{ alignedOffset }, _v)
                                    })
                                });
                            case size:
                                final arrayCt = macro : Array<$ct>;
                                final chained = [ for (i in 0...size) {
                                    final byteOffset    = element.offset + (i * element.stride);
                                    final alignedOffset = getAlignedOffset(element.type, byteOffset);

                                    macro this.write($v{ alignedOffset }, _v[$v{ i }]);
                                } ];

                                type.fields.push({
                                    name   : element.name,
                                    pos    : Context.currentPos(),
                                    access : [ APublic ],
                                    kind   : FProp('never', 'set', arrayCt)
                                });
                                type.fields.push({
                                    name   : 'set_${ element.name }',
                                    pos    : Context.currentPos(),
                                    access : [ APublic, AInline ],
                                    kind   : FFun({
                                        args : [ { name: '_v', type: arrayCt } ],
                                        ret  : arrayCt,
                                        expr : macro {
                                            if (_v.length != $v{ size })
                                            {
                                                throw new haxe.Exception('Haxe array does not match expected shader array size');
                                            }

                                            $b{ chained }

                                            return _v;
                                        }
                                    })
                                });
                        }
                    case None:
                        Context.error('Unsupported glsl type ${ element.type }', Context.currentPos());
                }
            }

            uboTypes.push(type);
        }
    }

    Context.defineModule('uk.aidanlee.flurry.api.gpu.shaders.uniforms.$clazz', uboTypes);

    return macro null;
}

private function glslTypeToComplexType(_type)
{
    return switch _type
    {
        case 'bool'            : Some(macro : Bool);
        case 'int', 'uint'     : Some(macro : Int);
        case 'float', 'double' : Some(macro : Float);
        case 'vec2'            : Some(macro : Vec2);
        case 'vec3'            : Some(macro : Vec3);
        case 'vec4'            : Some(macro : Vec4);
        case 'mat2'            : Some(macro : Mat2);
        case 'mat3'            : Some(macro : Mat3);
        case 'mat4'            : Some(macro : Mat4);
        case _                 : None;
    }
}

private function getAlignedOffset(_type, _offset)
{
    return switch _type
    {
        case 'double':
            Std.int(_offset / 8);
        case _:
            Std.int(_offset / 4);
    }
}