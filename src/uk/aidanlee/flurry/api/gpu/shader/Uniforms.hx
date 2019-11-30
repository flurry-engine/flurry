package uk.aidanlee.flurry.api.gpu.shader;

import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.maths.Vector2;

class Uniforms
{
    public final id : Int;

    public final int : Map<String, Int>;

    public final float : Map<String, Float>;

    public final vector4 : Map<String, Vector4>;

    public final vector2 : Map<String, Vector2>;

    public final matrix4 : Map<String, Matrix>;

    public function new()
    {
        id      = Hash.uniqueHash();
        int     = [];
        float   = [];
        vector4 = [];
        vector2 = [];
        matrix4 = [];
    }
}
