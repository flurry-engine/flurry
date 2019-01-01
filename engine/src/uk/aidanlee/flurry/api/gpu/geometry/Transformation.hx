package uk.aidanlee.flurry.api.gpu.geometry;

import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Quaternion;
import uk.aidanlee.flurry.api.maths.Matrix;

class Transformation
{
    /**
     * Position of this mesh.
     */
    public final position : Vector;

    /**
     * Origin for position and rotation.
     */
    public final origin : Vector;

    /**
     * Rotation for this mesh.
     */
    public final rotation : Quaternion;

    /**
     * Scale for this mesh.
     */
    public final scale : Vector;

    /**
     * Transformation matrix of this mesh.
     */
    public var transformation (get, null) : Matrix;

    inline function get_transformation() : Matrix {
        rotationMatrix.makeRotationFromQuaternion(rotation);
        originUndoMatrix.makeTranslation(-origin.x, -origin.y, -origin.z);

        // Translate to the origin.
        transformation.makeTranslation(origin.x, origin.y, origin.z);

        // Apply our rotation, set scale, and set position.
        transformation.multiply(rotationMatrix);
        transformation.scale(scale);
        transformation.setPosition(position);

        // Undo the origin translation to get the proper position.
        transformation.multiply(originUndoMatrix);

        return transformation;
    }

    /**
     * Contains a matrix to undo the origin.
     */
    final originUndoMatrix : Matrix;

    /**
     * Matrix to store this meshes rotation.
     */
    final rotationMatrix : Matrix;

    /**
     * Creates a new, default transformation.
     */
    inline public function new()
    {
        position = new Vector();
        origin   = new Vector();
        rotation = new Quaternion();
        scale    = new Vector(1, 1, 1);

        transformation   = new Matrix();
        originUndoMatrix = new Matrix();
        rotationMatrix   = new Matrix();
    }
}
