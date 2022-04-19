package uk.aidanlee.flurry.api.gpu;

import VectorMath;

class Colour
{
    public static var yellow (get, never) : Vec4;

    inline static function get_yellow() return vec4(1, 1, 0, 1);
}