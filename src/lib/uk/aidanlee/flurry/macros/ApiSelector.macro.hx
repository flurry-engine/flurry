package uk.aidanlee.flurry.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

macro function getGraphicsBackend(_resourceEvents : ExprOf<uk.aidanlee.flurry.api.resources.ResourceEvents>, _displayEvents : ExprOf<uk.aidanlee.flurry.api.display.DisplayEvents>, _windowConfig : ExprOf<uk.aidanlee.flurry.FlurryConfig.FlurryWindowConfig>, _rendererConfig : ExprOf<uk.aidanlee.flurry.FlurryConfig.FlurryRendererConfig>) : ExprOf<uk.aidanlee.flurry.api.gpu.Renderer>
{
    if (Context.defined('flurry-gpu-api'))
    {
        return switch Context.definedValue('flurry-gpu-api')
        {
            case 'mock'  : macro new uk.aidanlee.flurry.api.gpu.backend.MockBackend($_resourceEvents);
            case 'ogl3'  : macro new uk.aidanlee.flurry.api.gpu.backend.ogl3.OGL3Renderer($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.ogl3);
            case 'd3d11' : macro new uk.aidanlee.flurry.api.gpu.backend.d3d11.D3D11Renderer($_resourceEvents, $_displayEvents, $_windowConfig, $_rendererConfig.dx11);
            case other   : Context.error('unknown value of $other for flurry-gpu-api', Context.currentPos());
        }
    }
    else
    {
        Context.error('flurry-gpu-api not defined', Context.currentPos());
    }

    return macro new uk.aidanlee.flurry.api.gpu.backend.MockBackend($_resourceEvents);
}

/**
 * Adds concrete vertex and index output types to the class.
 * Using concrete types instead of dynamic dispatch allows use of haxe 4.2 overload functions.
 * These are currently implemented as inline functions so need a concrete type.
 */
macro function buildGraphicsContextOutputs() : Array<Field>
{
    final fields = Context.getBuildFields();

    if (Context.defined('flurry-gpu-api'))
    {
        switch Context.definedValue('flurry-gpu-api')
        {
            case 'd3d11':
                fields.push({
                    name   : 'vtxOutput',
                    doc    : null,
                    meta   : [],
                    access : [ APublic, AFinal ],
                    kind   : FVar(macro : uk.aidanlee.flurry.api.gpu.backend.d3d11.output.VertexOutput),
                    pos    : Context.currentPos()
                });
                fields.push({
                    name   : 'idxOutput',
                    doc    : null,
                    meta   : [],
                    access : [ APublic, AFinal ],
                    kind   : FVar(macro : uk.aidanlee.flurry.api.gpu.backend.d3d11.output.IndexOutput),
                    pos    : Context.currentPos()
                });
            case 'ogl3':
                fields.push({
                    name   : 'vtxOutput',
                    doc    : null,
                    meta   : [],
                    access : [ APublic, AFinal ],
                    kind   : FVar(macro : uk.aidanlee.flurry.api.gpu.backend.ogl3.output.VertexOutput),
                    pos    : Context.currentPos()
                });
                fields.push({
                    name   : 'idxOutput',
                    doc    : null,
                    meta   : [],
                    access : [ APublic, AFinal ],
                    kind   : FVar(macro : uk.aidanlee.flurry.api.gpu.backend.ogl3.output.IndexOutput),
                    pos    : Context.currentPos()
                });
            case other:
                Context.warning('Not yet implemented other api vertex outputs', Context.currentPos());
        }
    }
    else
    {
        Context.error('flurry-gpu-api not defined', Context.currentPos());
    }

    return fields;
}