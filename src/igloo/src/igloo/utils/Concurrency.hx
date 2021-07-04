package igloo.utils;

@:keep
@:unreflective
@:include('thread')
extern class Concurrency
{
    /**
     * Returns the number of concurrent threads supported by the implementation. The value should be considered only a hint. 
     * @return Number of concurrent threads supported. If the value is not well defined or not computable, returns ​0​.
     */
    @:native('std::thread::hardware_concurrency') static function hardwareConcurrency() : Int;
}