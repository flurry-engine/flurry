package uk.aidanlee.flurry.api.core;

enum Result<T, E>
{
    Success(_data : T);
    Failure(_data : E);
}