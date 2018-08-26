package uk.aidanlee.gpu;

import uk.aidanlee.maths.Matrix;
import uk.aidanlee.maths.Vector;

class Shader
{
    public final shaderID : Int;

    public final int : Map<String, Int>;

    public final vector4 : Map<String, Vector>;

    public final matrix4 : Map<String, Matrix>;

    public function new(_id : Int)
    {
        shaderID = _id;
        
        int     = new Map();
        vector4 = new Map();
        matrix4 = new Map();
    }
}
