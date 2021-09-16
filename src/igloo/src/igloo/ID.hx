package igloo;

import hx.strings.RandomStrings;

macro function generateID()
{
    final guid = Std.parseInt(RandomStrings.randomDigits(9));

    return macro $v{ guid };
}