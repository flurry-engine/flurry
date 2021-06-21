package igloo.macros;

using StringTools;

macro function getHostPlatformName()
{
    return macro $v{ Sys.systemName().toLowerCase() };
}