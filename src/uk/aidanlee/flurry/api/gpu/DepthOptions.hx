package uk.aidanlee.flurry.api.gpu;

@:structInit
class DepthOptions
{
    public final depthTesting : Bool;
    public final depthMasking : Bool;
    public final depthFunction : ComparisonFunction;
}