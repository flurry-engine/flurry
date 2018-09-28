package uk.aidanlee.maths;

@:enum abstract ComponentOrder(Int) from Int to Int
{
    var XYZ = 0;
    var YXZ = 1;
    var ZXY = 2;
    var ZYX = 3;
    var YZX = 4;
    var XZY = 5;
}