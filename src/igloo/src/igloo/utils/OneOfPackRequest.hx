package igloo.utils;

import igloo.processors.PackRequest;
import haxe.ds.Either;

abstract OneOfPackRequest(Either<PackRequest, Array<PackRequest>>) from Either<PackRequest, Array<PackRequest>> to Either<PackRequest, Array<PackRequest>>
{
    @:from inline static function fromPackRequest(_request : PackRequest) : OneOfPackRequest
    {
        return Left(_request);
    }

    @:from inline static function fromPackRequests(_requests : Array<PackRequest>) : OneOfPackRequest
    {
        return Right(_requests);
    }
}