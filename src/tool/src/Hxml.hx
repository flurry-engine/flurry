enum abstract DCE(String) from String to String
{
    var no;
    var std;
    var full;
}

abstract Hxml(StringBuf)
{
    // Targets

    public var js (never, set) : String;

    inline function set_js(_v : String) return append('--js $_v');

    public var cpp (never, set) : String;

    inline function set_cpp(_v : String) return append('--cpp $_v');

    public var hl (never, set) : String;

    inline function set_hl(_v : String) return append('--hl $_v');

    // Compilation

    public var main (never, set) : String;

    inline function set_main(_v : String) return append('-m $_v');

    public function addHxml(_hxml : String) append(_hxml);

    public function addClassPath(_path : String) append('-p $_path');

    public function addLibrary(_lib : String, _version : Null<String> = null) append('-lib $_lib${ _version != null ? ':$_version' : '' }');

    public function addDefine(_define : String, _value : Null<String> = null) append('-D $_define${ _value != null ? '=$_value' : '' }');

    public function addResource(_file : String, _name : Null<String> = null) append('-r $_file${ _name != null ? '@$_name' : '' }');

    public function addMacro(_macro : String) append('--macro $_macro');

    // Optimisations

    public var dce (never, set) : String;

    inline function set_dce(_v : DCE) return append('--dce $_v');

    public function noTraces() append('--no-traces');

    public function noOutput() append('--no-output');

    public function noInline() append('--no-inline');

    public function noOptimisations() append('--no-opt');

    // Debug

    public function verbose() append('--verbose');

    public function debug() append('--debug');

    public function prompt() append('--prompt');

    public function times() append('--times');

    public function new()
    {
        this = new StringBuf();
    }

    public function toString() return this.toString();

    inline function append(_line : String) : String
    {
        this.add('$_line\n');

        return _line;
    }
}