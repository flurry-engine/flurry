package uk.aidanlee.flurry.api.gpu.pipeline;

enum abstract BlendOp(Int) to Int
{
    var Add;
    var Subtract;
    var ReverseSubtract;
    var Min;
    var Max;
}