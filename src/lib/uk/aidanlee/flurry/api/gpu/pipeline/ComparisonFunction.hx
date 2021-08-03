package uk.aidanlee.flurry.api.gpu.pipeline;

enum abstract ComparisonFunction(Int) to Int
{
    var Always;
    var Never;
    var Equal;
    var LessThan;
    var LessThanOrEqual;
    var GreaterThan;
    var GreaterThanOrEqual;
    var NotEqual;
}