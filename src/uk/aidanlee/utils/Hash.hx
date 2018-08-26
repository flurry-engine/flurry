package uk.aidanlee.utils;

/**
 * Hash class provides several static functions to return unique IDs and hash values.
 */
class Hash
{
    /**
     * Generates and returns a unique base62 string from a value.
     * 
     * http://www.anotherchris.net/csharp/friendly-unique-id-generation-part-2/#base62
     * 
     * @param _val Value to generate uniqueID for. If null a random value is used.
     * @return String
     */
    public static inline function uniqueID(_val : Int = null) : String
    {
        if (_val == null)
        {
            _val = Std.random(0x7fffffff);
        }

        function valToChar(_value : Int) : String
        {
            if (_value > 9)
            {
                var ascii = (65 + (_value - 10));
                if (ascii > 90)
                {
                    ascii += 6;
                }

                return String.fromCharCode(ascii);
            }
            else
            {
                return Std.string(_value).charAt(0);
            }
        }

        var r = Std.int(_val % 62);
        var q = Std.int(_val / 62);
        if (q > 0)
        {
            return uniqueID(q) + valToChar(r);
        }
        else
        {
            return Std.string(valToChar(r));
        }
    }

    /**
     * When provided string returns an integer hash.
     * @param _in String to hash.
     * @return Int
     */
    public static inline function hash(_in : String) : Int
    {
        var hash = 5381;
        for(i in 0..._in.length)
        {
            hash = ((hash << 5) + hash) + _in.charCodeAt(i);
        }

        return hash;
    }

    /**
     * Return a unique hash.
     * Hashes a random base62 encoded string.
     * @return Int
     */
    public static inline function uniqueHash() : Int
    {
        return hash(uniqueID());
    }
}
