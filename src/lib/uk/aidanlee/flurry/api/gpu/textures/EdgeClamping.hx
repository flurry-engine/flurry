package uk.aidanlee.flurry.api.gpu.textures;

enum abstract EdgeClamping(Int) to Int
{
    var Wrap;
    var Mirror;
    var Clamp;
    var Border;
}