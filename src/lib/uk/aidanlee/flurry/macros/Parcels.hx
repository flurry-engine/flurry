package uk.aidanlee.flurry.macros;

import haxe.macro.Printer;
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

var totalResources = 0;

macro function loadParcelMeta(_name : String, _path : String)
{
    final meta  = (Json.parse(File.getContent(_path)) : ParcelMeta);
    final clazz = _name.toUpperCaseFirstChar();
    final built = macro class $clazz {}
    final print = new Printer();

    totalResources += meta.pages.length;

    for (asset in meta.assets)
    {
        totalResources += asset.produced.length;

        for (produced in asset.produced)
        {
            built.fields.push({
                name: produced.name,
                pos : Context.currentPos(),
                kind: FVar(macro : Int, macro $v{ produced.id }),
                access: [ APublic, AStatic, AInline ]
            });
        }
    }

    Context.defineModule('uk.aidanlee.flurry.api.resources.Parcels', [ built ]);

    return macro null;
}

macro function getTotalResourceCount()
{
    return macro $v{ totalResources };
}