package uk.aidanlee.flurry.modules.imgui;

import cpp.Char;

abstract ImTextBuffer(Array<Char>) from Array<Char> to Array<Char>
{
    public function new(_length : Int, _initialString : String = '')
    {
        this = [ for (i in 0..._length) 0x0 ];
        setString(_initialString);
    }

    public function setString(_text : String)
    {
        for (i in 0..._text.length)
        {
            this[i] = _text.charCodeAt(i);
        }
    }

    public function toString() : String
    {
        var buf = new StringBuf();
        for (char in this) buf.addChar(char);

        return buf.toString();
    }
}
