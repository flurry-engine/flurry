package igloo.utils;

import haxe.Exception;
import haxe.ds.Either;

abstract OneOf<A, B>(Either<A, B>) from Either<A, B> to Either<A, B>
{
    @:from inline static function fromA<A, B>(_a : A) : OneOf<A, B>
    {
        return Left(_a);
    }

    @:from inline static function fromB<A, B>(_b : B) : OneOf<A, B>
    {
        return Right(_b);
    }
    
    @:to public inline function toA()
    {
        return switch(this)
        {
            case Left(a): a;
            default: throw new Exception('this is not A');
        }
    }

    @:to public inline function toB()
    {
        return switch(this)
        {
            case Right(b): b;
            default: throw new Exception('this is not B');
        }
    }
}