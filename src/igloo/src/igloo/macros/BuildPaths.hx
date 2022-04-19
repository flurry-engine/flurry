package igloo.macros;

import haxe.macro.Context;

macro function getIglooCodePath()
{
    return switch Context.definedValue('IGLOO_SRC_CODEPATH')
    {
        case null: Context.error('IGLOO_SRC_CODEPATH was not defined', Context.currentPos());
        case path: macro hx.files.Path.of($v{ path });
    }
}

macro function getIglooDllExportFile()
{
    return switch Context.definedValue('IGLOO_DLL_EXPORT')
    {
        case null: Context.error('IGLOO_DLL_EXPORT was not defined', Context.currentPos());
        case path: macro hx.files.Path.of($v{ path });
    }
}

macro function getIglooBuiltInScriptsDir()
{
    return switch Context.definedValue('IGLOO_BUILTIN_SCRIPTS')
    {
        case null: Context.error('IGLOO_BUILTIN_SCRIPTS was not defined', Context.currentPos());
        case path: macro hx.files.Path.of($v{ path });
    }
}

macro function getFlurryLibSrcPath()
{
    return switch Context.definedValue('FLURRY_LIB_SRC')
    {
        case null: Context.error('FLURRY_LIB_SRC was not defined', Context.currentPos());
        case path: macro hx.files.Path.of($v{ path });
    }
}