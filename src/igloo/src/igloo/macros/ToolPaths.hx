package igloo.macros;

macro function getMsdfAtlasGenPath(_outputDir : ExprOf<hx.files.Path>) : ExprOf<hx.files.Path>
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $e{ _outputDir }.join('msdf-atlas-gen.exe');
        case _:
            macro $e{ _outputDir }.join('msdf-atlas-gen');
    }
}

macro function getGlslangPath(_outputDir : ExprOf<hx.files.Path>) : ExprOf<hx.files.Path>
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $e{ _outputDir }.join('glslangValidator.exe');
        case _:
            macro $e{ _outputDir }.join('glslangValidator');
    }
}

macro function getSprivCrossPath(_outputDir : ExprOf<hx.files.Path>) : ExprOf<hx.files.Path>
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $e{ _outputDir }.join('spirv-cross.exe');
        case _:
            macro $e{ _outputDir }.join('spirv-cross');
    }
}

macro function getMsdfAtlasGenFileEntry()
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $v{ 'msdf-atlas-gen.exe' }
        case _:
            macro $v{ 'msdf-atlas-gen' }
    }
}

macro function getGlslangFileEntry()
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $v{ 'bin/glslangValidator.exe' }
        case _:
            macro $v{ 'bin/glslangValidator' }
    }
}

macro function getSpirvCrossFileEntry()
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $v{ 'bin/spirv-cross.exe' }
        case _:
            macro $v{ 'bin/spirv-cross' }
    }
}