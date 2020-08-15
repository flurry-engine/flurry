package uk.aidanlee.flurry.macros;

import haxe.macro.Context;
import uk.aidanlee.flurry.api.gpu.RendererBackend;

class ApiSelector
{
    public static macro function getGraphicsApi() : ExprOf<RendererBackend>
    {
        if (Context.defined('flurry-gpu-api'))
        {
            return switch Context.definedValue('flurry-gpu-api')
            {
                case 'mock'  : macro $v{ Mock };
                case 'ogl3'  : macro $v{ Ogl3 };
                case 'd3d11' : macro $v{ Dx11 };
                case other   : Context.error('unknown value of $other for flurry-gpu-api', Context.currentPos());
            }
        }
        else
        {
            Context.error('flurry-gpu-api not defined', Context.currentPos());
        }

        return macro $v{ Mock };
    }

    public static macro function getGraphicsBackend(_resourceEvents : ExprOf<uk.aidanlee.flurry.api.resources.ResourceEvents>, _displayEvents : ExprOf<uk.aidanlee.flurry.api.display.DisplayEvents>, _windowConfig : ExprOf<uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig>, _rendererConfig : ExprOf<uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig>) : ExprOf<uk.aidanlee.flurry.api.gpu.backend.IRendererBackend>
    {
        if (Context.defined('flurry-gpu-api'))
        {
            return switch Context.definedValue('flurry-gpu-api')
            {
                case 'mock'  : macro new uk.aidanlee.flurry.api.gpu.backend.MockBackend($_resourceEvents);
                case 'ogl3'  : macro new uk.aidanlee.flurry.api.gpu.backend.OGL3Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.ogl3);
                case 'd3d11' : macro new uk.aidanlee.flurry.api.gpu.backend.DX11Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.dx11);
                case other   : Context.error('unknown value of $other for flurry-gpu-api', Context.currentPos());
            }
        }
        else
        {
            Context.error('flurry-gpu-api not defined', Context.currentPos());
        }

        return macro new uk.aidanlee.flurry.api.gpu.backend.MockBackend($_resourceEvents);
    }
}