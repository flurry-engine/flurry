package uk.aidanlee.flurry.api;

import haxe.io.Input;

function readPrefixedString(_input : Input)
{
    final len = _input.readInt32();
    final str = _input.readString(len);

    return str;
}