package uk.aidanlee.flurry.api.gpu;

enum abstract RendererBackend(Int) from Int
{
    var Ogl3;
    var Ogl4;
    var Dx11;
    var Mock;
}