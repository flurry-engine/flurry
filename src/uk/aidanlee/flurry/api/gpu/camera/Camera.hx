package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.gpu.state.ViewportState;

/**
 * Base camera class.
 * Contains transformations, projection, view, and combined matrices, and a viewport.
 */
class Camera
{
    public final type : CameraType;

    /**
     * Projection matrix of this camera.
     */
    public final projection : Matrix;

    /**
     * The view matrix of this camera.
     */
    public final view : Matrix;

    public var viewport : ViewportState;

    public function new(_type : CameraType)
    {
        type       = _type;
        projection = new Matrix();
        view       = new Matrix();
        viewport   = None;
    }
}
