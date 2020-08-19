package uk.aidanlee.flurry.api.core;

import haxe.macro.Context;

enum LogType
{
    Info;
    Success;
    Error;
    Item;
}

class Log
{
    public static macro function log(_data : ExprOf<String>, _type : ExprOf<LogType>)
    {
        if (Context.defined('console.hx'))
        {
            return macro switch ($_type)
            {
                case Info    : Console.log($_data);
                case Success : Console.success($_data);
                case Error   : Console.error($_data);
                case Item    : Console.printlnFormatted('<b,light_blue> •<//> ' + $_data);
            }
        }
        else
        {
            return macro Sys.println($_data);
        }
    }
}