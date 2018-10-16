package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.gpu.geometry.Transformation;

/**
 * Base camera class.
 * Contains transformations, projection, view, and combined matrices, and a viewport.
 */
class Camera
{
    /**
     * Projection matrix of this camera.
     */
    public final projection : Matrix;

    /**
     * The view matrix of this camera.
     */
    public final view : Matrix;

    /**
     * Matrix of the invertex view.
     */
    public final viewInverted : Matrix;

    /**
     * The viewspace viewport of this camera.
     */
    public final viewport : Rectangle;

    /**
     * The transformation of this camera.
     * The resulting transformation matrix is used as this cameras view matrix.
     */
    public final transformation : Transformation;

    /**
     * Creates a empty camera.
     * By default his camera class only contains identity matrices.
     */
    public function new()
    {
        transformation = new Transformation();
        projection     = new Matrix();
        view           = new Matrix();
        viewInverted   = new Matrix();
        viewport       = new Rectangle();
    }

    /**
     * Empty update function.
     * Cameras should update their projection and view matrices here.
     */
    public function update()
    {
        //
    }
}
