package uk.aidanlee.flurry.api.gpu.pipeline;

enum abstract StencilFunction(Int) to Int
{
    var Keep;
    var Zero;
    var Replace;
    var Invert;
    var Increment;
    var IncrementWrap;
    var Decrement;
    var DecrementWrap;
}