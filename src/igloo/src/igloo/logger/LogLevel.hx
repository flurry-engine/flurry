package igloo.logger;

enum abstract LogLevel(Int)
{
    var Verbose;
    var Debug;
    var Information;
    var Warning;
    var Error;

    @:op(A>B) public function gt(_a : LogLevel) : Bool;

    @:op(A<B) public function lt(_a : LogLevel) : Bool;

    @:op(A>=B) public function geqt(_a : LogLevel) : Bool;

    @:op(A<=B) public function leqt(_a : LogLevel) : Bool;

    @:to public function toString()
    {
        return switch (cast this : LogLevel)
        {
            case Verbose: 'LOG';
            case Debug: 'DBG';
            case Information: 'INF';
            case Warning: 'WRN';
            case Error: 'ERR';
        }
    }

    @:from public static function fromString(_v : String)
    {
        return switch _v
        {
            case 'LOG', 'verbose', 'all': Verbose;
            case 'DBG', 'debug': Debug;
            case 'WRN', 'warning': Warning;
            case 'ERR', 'error': Error;
            case _: Information;
        }
    }
}