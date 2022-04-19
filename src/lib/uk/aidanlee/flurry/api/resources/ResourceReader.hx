package uk.aidanlee.flurry.api.resources;

import haxe.io.Input;
import haxe.exceptions.NotImplementedException;

class ResourceReader
{
    public function new()
    {
        //
    }

    public function ids() : Array<String>
    {
        throw new NotImplementedException();
    }

    public function read(_input : Input) : Resource
    {
        throw new NotImplementedException();
    }
}