package uk.aidanlee.flurry.api.maths;

/**
 * Represents a local or world transformation.
 */
class Spatial
{
    /**
     * Matrix storing the overall transformation.
     */
    public final matrix : Matrix;

    /**
     * The position of this transform.
     */
    public final position : Vector;

    /**
     * The scale of this transform.
     */
    public final scale : Vector;

    /**
     * The rotation of this transform.
     */
    public final rotation : Quaternion;

    public function new()
    {
        matrix   = new Matrix();
        position = new Vector();
        scale    = new Vector(1, 1, 1);
        rotation = new Quaternion();
    }

    /**
     * Update the individual components to match the matrix.
     */
    public function decompose()
    {
        matrix.decompose(position, rotation, scale);
    }

    /**
     * Set the matrix to match the individual components.
     */
    public function compose()
    {
        matrix.compose(position, rotation, scale);
    }
}