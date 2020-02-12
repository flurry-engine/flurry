package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Matrix;
import uk.aidanlee.flurry.api.maths.Transformation;
import uk.aidanlee.flurry.api.gpu.state.ViewportState;

enum abstract CameraOrigin(Int)
{
    var TopLeft;
    var BottomLeft;
}

enum abstract CameraNdcRange(Int)
{
    var ZeroToNegativeOne;
    var NegativeOneToNegativeOne;
}

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

    /**
     * Viewport of the camera.
     */
    public var viewport : ViewportState;

    /**
     * Position of this camera in the world.
     */
    public var transformation : Transformation;

    public var position (get, never) : Vector3;

    inline function get_position() : Vector3 return transformation.position;

    public var scale (get, never) : Vector3;

    inline function get_scale() : Vector3 return transformation.scale;

    public var origin (get, never) : Vector3;

    inline function get_origin() : Vector3 return transformation.origin;

    /**
     * Where the current renderer considers the origin of the screen to be.
     */
    final screenOrigin : CameraOrigin;

    /**
     * The ndc range of the z axis for the current renderer.
     */
    final ndcRandge : CameraNdcRange;

    public function new(_type : CameraType, _origin : CameraOrigin, _ndcRange : CameraNdcRange)
    {
        type           = _type;
        screenOrigin   = _origin;
        ndcRandge      = _ndcRange;
        projection     = new Matrix();
        view           = new Matrix();
        transformation = new Transformation();
        viewport       = None;
    }

    function rebuildCameraMatrices()
    {
        //
    }
}
