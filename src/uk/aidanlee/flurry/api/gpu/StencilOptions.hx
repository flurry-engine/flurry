package uk.aidanlee.flurry.api.gpu;

@:structInit
class StencilOptions
{
    public final stencilTesting : Bool;

    public final stencilFrontMask : Int;
    public final stencilFrontFunction : ComparisonFunction;
    public final stencilFrontTestFail : StencilFunction;
    public final stencilFrontDepthTestFail : StencilFunction;
    public final stencilFrontDepthTestPass : StencilFunction;

    public final stencilBackMask : Int;
    public final stencilBackFunction : ComparisonFunction;
    public final stencilBackTestFail : StencilFunction;
    public final stencilBackDepthTestFail : StencilFunction;
    public final stencilBackDepthTestPass : StencilFunction;
}