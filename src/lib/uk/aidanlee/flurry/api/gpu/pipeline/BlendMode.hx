package uk.aidanlee.flurry.api.gpu.pipeline;

enum abstract BlendMode(Int) to Int
{
    var Zero;
    var One;
    var SrcAlphaSaturate;
    var SrcColor;
    var OneMinusSrcColor;
    var SrcAlpha;
    var OneMinusSrcAlpha;
    var DstAlpha;
    var OneMinusDstAlpha;
    var DstColor;
    var OneMinusDstColor;
}