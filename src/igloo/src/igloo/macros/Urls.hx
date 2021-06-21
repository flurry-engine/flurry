package igloo.macros;

macro function getMsdfAtlasGenUrl()
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $v{ 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/windows-latest.tar.gz' }
        case 'Mac':
            macro $v{ 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/macOS-latest.tar.gz' }
        case other:
            macro $v{ 'https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/ubuntu-latest.tar.gz' }
    }
}

macro function getGlslangUrl()
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $v{ 'https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-windows-x64-Release.zip' }
        case 'Mac':
            macro $v{ 'https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-osx-Release.zip' }
        case other:
            macro $v{ 'https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-linux-Release.zip' }
    }
}

macro function getSpirvCrossUrl()
{
    return switch Sys.systemName()
    {
        case 'Windows':
            macro $v{ 'https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-vs2017-64bit-b1082c10af.tar.gz' }
        case 'Mac':
            macro $v{ 'https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-clang-macos-64bit-b1082c10af.tar.gz' }
        case other:
            macro $v{ 'https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-gcc-trusty-64bit-b1082c10af.tar.gz' }
    }
}