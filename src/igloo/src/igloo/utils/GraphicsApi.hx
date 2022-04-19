package igloo.utils;

import haxe.Exception;
import igloo.macros.Platform;

enum abstract GraphicsApi(String) to String
{
    var Mock = 'mock';
    var Ogl3 = 'ogl3';
    var D3d11 = 'd3d11';

    @:from public static function fromString(_v : String) : GraphicsApi
    {
        return switch _v
        {
            case 'mock': Mock;
            case 'ogl3': Ogl3;
            case 'd3d11' if (getHostPlatformName() == 'windows'): D3d11;
            case 'auto':
                if (getHostPlatformName() == 'windows')
                {
                    D3d11;
                }
                else
                {
                    Ogl3;
                }
            case other:
                throw new Exception('graphics api $other is not supported on ${ getHostPlatformName() }');
        }
    }
}