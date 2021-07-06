package igloo.processors;

import haxe.ds.Either;

enum AssetResponse
{
    Packed(_packed : Either<PackedAsset, Array<PackedAsset>>);
    NotPacked(_id : String);
}