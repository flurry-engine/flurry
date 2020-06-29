package uk.aidanlee.flurry.api.stream;

enum Compression
{
    None;
    Deflate(_level : Int, _chunkSize : Int);
}