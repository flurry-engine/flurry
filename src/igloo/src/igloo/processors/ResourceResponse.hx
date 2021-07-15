package igloo.processors;

import igloo.processors.PackedResource;

enum ResourceResponse
{
    Packed(_packed : PackedResource);
    NotPacked(_name : String, _id : Int);
}