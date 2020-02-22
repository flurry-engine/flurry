package uk.aidanlee.flurry.api.gpu;

enum abstract ComparisonFunction(Int)
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