package igloo.processors;

import igloo.processors.PackedResource;
import haxe.ds.Either;

enum AssetResponse
{
    Packed(_packed : Either<PackedResource, Array<PackedResource>>);
    NotPacked(_name : String, _id : Int);
}