package uk.aidanlee.flurry.macros;

import haxe.macro.Context;
import uk.aidanlee.flurry.api.gpu.RendererBackend;

class ApiSelector
{
    public static macro function getGraphicsApi() : ExprOf<RendererBackend>
    {
        if (Context.defined('flurry-api-mock'))
        {
            return macro $v{ Mock };
        }

        if (Context.defined('flurry-api-ogl3'))
        {
            return macro $v{ Ogl3 };
        }

        if (Context.defined('flurry-api-ogl4') && Sys.systemName() != 'Mac')
        {
            return macro $v{ Ogl4 };
        }

        if (Context.defined('flurry-api-dx11') && Sys.systemName() == 'Windows')
        {
            return macro $v{ Dx11 };
        }

        return switch Sys.systemName()
        {
            case 'Windows': macro $v{ Dx11 }
            case 'Mac', 'Linux': macro $v{ Ogl3 }
            case _other:
                Context.error('No graphics backend avaliable for $_other', Context.currentPos());
        }
    }

    public static macro function getGraphicsBackend(_resourceEvents : ExprOf<uk.aidanlee.flurry.api.resources.ResourceEvents>, _displayEvents : ExprOf<uk.aidanlee.flurry.api.display.DisplayEvents>, _windowConfig : ExprOf<uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig>, _rendererConfig : ExprOf<uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig>) : ExprOf<uk.aidanlee.flurry.api.gpu.backend.IRendererBackend>
    {
        if (Context.defined('flurry-api-mock'))
        {
            return macro new uk.aidanlee.flurry.api.gpu.backend.MockBackend($_resourceEvents);
        }

        if (Context.defined('flurry-api-ogl3'))
        {
            return macro new uk.aidanlee.flurry.api.gpu.backend.OGL3Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.ogl3);
        }

        if (Context.defined('flurry-api-ogl4'))
        {
            if (Sys.systemName() == 'Mac')
            {
                Context.warning('Ogl4 not available on Mac, falling back to auto graphics api selection', Context.currentPos());
            }
            else
            {
                return macro new uk.aidanlee.flurry.api.gpu.backend.OGL4Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.ogl4);
            }
        }

        if (Context.defined('flurry-api-dx11'))
        {
            if (Sys.systemName() == 'Windows')
            {
                return macro new uk.aidanlee.flurry.api.gpu.backend.DX11Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.dx11);
            }
            else
            {
                Context.warning('D3D11 backend only available on Windows, falling back to auto graphics api selection', Context.currentPos());
            }
        }

        return switch Sys.systemName()
        {
            case 'Windows':
                macro new uk.aidanlee.flurry.api.gpu.backend.DX11Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.dx11);
            case 'Mac', 'Linux':
                macro new uk.aidanlee.flurry.api.gpu.backend.OGL3Backend($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.ogl3);
            case _other:
                Context.error('No graphics backend avaliable for $_other', Context.currentPos());
        }
    }
}