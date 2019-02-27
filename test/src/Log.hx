package;

/**
 * Simple log class to print out coloured text on platforms which support it.
 */
class Log
{
    /**
     * Collection of ANSI colour codes with names.
     */
    public static var ansiColours:Map<String, String> = [
        "black"   => "\033[0;30m",
        "red"     => "\033[31m"  ,
        "green"   => "\033[32m"  ,
        "yellow"  => "\033[33m"  ,
        "blue"    => "\033[1;34m",
        "magenta" => "\033[1;35m",
        "cyan"    => "\033[0;36m",
        "grey"    => "\033[0;37m",
        "white"   => "\033[1;37m",
        "none"    => "\033[0m"
    ];

    /**
     * Maps colours onto names for use in functions.
     */
    public static var messageModes:Map<String, String> = [
        "debug"   => ansiColours["cyan" ],
        "info"    => ansiColours["white"],
        "error"   => ansiColours["red"  ],
        "default" => ansiColours["none" ]
    ];

    /**
     * Prints the message to the console with the debug colour.
     *
     * @param   _message    The message to print.
     */
    public static inline function debug(_message:String)
    {
        print(_message, messageModes["debug"]);
    }

    /**
     * Prints the message to the console with the error colour.
     *
     * @param   _message    The message to print.
     */
    public static inline function error(_message:String)
    {
        print(_message, messageModes["error"]);
    }

    /**
     * Prints the message to the console with the info colour.
     *
     * @param   _message    The message to print.
     */
    public static inline function info(_message:String)
    {
        print(_message, messageModes["info"]);
    }

    /**
     * Prints the message to the console, optionally with the colour provided.
     * Colour will only be used on non-windows platforms as cmd does not support ANSI codes.
     *
     * @param   _message    The message to print.
     * @param   _colour     The message colour, leaving blank will use the terminal default.
     */
    public static inline function print(_message:String, ?_colour:String)
    {
        #if sys
            if (Sys.systemName() == "Windows")
            {
                Sys.println(_message);
            }
            else
            {
                if (_colour == null)
                {
                    _colour = ansiColours["none"];
                }

                Sys.println(_colour + _message + ansiColours["none"]);
            }
        #else
            trace(_message);
        #end
    }
}