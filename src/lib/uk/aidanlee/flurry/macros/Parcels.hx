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

private var totalParcels   = 0;
private var totalResources = 0;

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
                kind: FVar(macro : uk.aidanlee.flurry.api.resources.ResourceID, macro new uk.aidanlee.flurry.api.resources.ResourceID($v{ produced.id })),
                access: [ APublic, AStatic, AFinal ]
            });
        }
    }

    built.pack = [ 'uk', 'aidanlee', 'flurry', 'api', 'resources', 'parcels' ];

    final fullType = 'uk.aidanlee.flurry.api.resources.parcels.${ clazz }';

    try
    {
        Context.getType(fullType);

        // What should we do if the type is already defined?!
    }
    catch (e)
    {
        // not defined, so do so now.

        Context.defineType(built);
    }

    return macro null;
}

macro function getTotalResourceCount()
{
    return macro $v{ totalResources };
}