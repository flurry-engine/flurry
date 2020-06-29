package uk.aidanlee.flurry.api.stream;

enum abstract ImageFormat(Int) to Int from Int
{
    var RawBGRA;
    var Png;
    var Jpeg;
}