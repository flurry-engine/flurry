package uk.aidanlee.flurry.api.gpu;

enum abstract StencilFunction(Int)
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