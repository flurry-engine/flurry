package igloo.utils;

import haxe.Exception;
import igloo.processors.PackedAsset;
import haxe.ds.Either;

abstract OneOfPackedAsset(Either<PackedAsset, Array<PackedAsset>>) from Either<PackedAsset, Array<PackedAsset>> to Either<PackedAsset, Array<PackedAsset>>
{
    @:from inline static function fromPackedAsset(_asset : PackedAsset) : OneOfPackedAsset
    {
        return Left(_asset);
    }

    @:from inline static function fromPackedAssets(_packed : Array<PackedAsset>) : OneOfPackedAsset
    {
        return Right(_packed);
    }

    @:to public inline function toAsset()
    {
        return switch this
        {
            case Left(v): v;
            case _: throw new Exception('this was not a packed asset');
        }
    }

    @:to public inline function toAssets()
    {
        return switch this
        {
            case Right(v): v;
            case _: throw new Exception('this was not an array of packed assets');
        }
    }
}