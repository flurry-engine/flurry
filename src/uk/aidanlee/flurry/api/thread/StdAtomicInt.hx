package uk.aidanlee.flurry.api.thread;

@:keep
@:structAccess
@:unreflective
@:include('atomic')
@:native('std::atomic_int')
extern class StdAtomicInt
{
    @:native('std::atomic_int')
    static function create(_desired : Int) : StdAtomicInt;

    function store(_desired : Int) : Void;

    function load() : Int;

    function exchange(_desired : Int) : Int;

    function fetch_add(_arg : Int) : Int;

    function fetch_sub(_arg : Int) : Int;

    function fetch_and(_arg : Int) : Int;

    function fetch_or(_arg : Int) : Int;

    function fetch_xor(_arg : Int) : Int;
}
