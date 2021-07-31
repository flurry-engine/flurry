package uk.aidanlee.flurry.api.utils;

import Mat4;
import Mat3;
import Mat2;
import Vec4;
import Vec3;
import Vec2;
import haxe.io.Output;

overload extern inline function writeMatrix(_output : Output, _mat : Mat4)
{
    final data = (_mat : Mat4Data);
    _output.writeFloat(data.c0.x);
    _output.writeFloat(data.c0.y);
    _output.writeFloat(data.c0.z);
    _output.writeFloat(data.c0.w);
    _output.writeFloat(data.c1.x);
    _output.writeFloat(data.c1.y);
    _output.writeFloat(data.c1.z);
    _output.writeFloat(data.c1.w);
    _output.writeFloat(data.c2.x);
    _output.writeFloat(data.c2.y);
    _output.writeFloat(data.c2.z);
    _output.writeFloat(data.c2.w);
    _output.writeFloat(data.c3.x);
    _output.writeFloat(data.c3.y);
    _output.writeFloat(data.c3.z);
    _output.writeFloat(data.c3.w);
}

overload extern inline function writeMatrix(_output : Output, _mat : Mat3)
{
    final data = (_mat : Mat3Data);
    _output.writeFloat(data.c0.x);
    _output.writeFloat(data.c0.y);
    _output.writeFloat(data.c0.z);
    _output.writeFloat(data.c1.x);
    _output.writeFloat(data.c1.y);
    _output.writeFloat(data.c1.z);
    _output.writeFloat(data.c2.x);
    _output.writeFloat(data.c2.y);
    _output.writeFloat(data.c2.z);
}

overload extern inline function writeMatrix(_output : Output, _mat : Mat2)
{
    final data = (_mat : Mat2Data);
    _output.writeFloat(data.c0.x);
    _output.writeFloat(data.c0.y);
    _output.writeFloat(data.c1.x);
    _output.writeFloat(data.c1.y);
}

overload extern inline function writeVector(_output : Output, _vec : Vec4)
{
    _output.writeFloat(_vec.x);
    _output.writeFloat(_vec.y);
    _output.writeFloat(_vec.z);
    _output.writeFloat(_vec.w);
}

overload extern inline function writeVector(_output : Output, _vec : Vec3)
{
    _output.writeFloat(_vec.x);
    _output.writeFloat(_vec.y);
    _output.writeFloat(_vec.z);
}

overload extern inline function writeVector(_output : Output, _vec : Vec2)
{
    _output.writeFloat(_vec.x);
    _output.writeFloat(_vec.y);
}