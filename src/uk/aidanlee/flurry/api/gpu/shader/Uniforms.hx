package uk.aidanlee.flurry.api.gpu.shader;

import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Vector;

class Uniforms
{
    public final id : Int;

    public final int : Map<String, Int>;

    public final float : Map<String, Float>;

    public final vector4 : Map<String, Vector>;

    public final matrix4 : Map<String, Matrix>;

    public function new()
    {
        id      = Hash.uniqueHash();
        int     = [];
        float   = [];
        vector4 = [];
        matrix4 = [];
    }
}
