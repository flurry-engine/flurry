package uk.aidanlee.flurry.api.gpu.pipeline;

enum abstract PrimitiveType(Int)
{
    var Points;
    var Lines;
    var LineStrip;
    var Triangles;
    var TriangleStrip;
}