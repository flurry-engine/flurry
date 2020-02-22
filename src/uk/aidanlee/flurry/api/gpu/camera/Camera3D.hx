package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.gpu.camera.Camera.CameraNdcRange;
import uk.aidanlee.flurry.api.gpu.camera.Camera.CameraOrigin;

class Camera3D extends Camera
{
    public var fov (default, set) : Float;

    inline function set_fov(_v : Float) : Float
    {
        return fov = _v;
    }

    public var aspect (default, set) : Float;

    inline function set_aspect(_v : Float) : Float
    {
        return aspect = _v;
    }

    public var near (default, set) : Float;

    inline function set_near(_v : Float) : Float
    {
        return near = _v;
    }

    public var far (default, set) : Float;

    inline function set_far(_v : Float) : Float
    {
        return far = _v;
    }

    final perspectiveYFlipVector = new Vector3(1, -1, 1);

    public function new(_fov : Float, _aspect : Float, _near : Float, _far : Float, _origin : CameraOrigin, _ndcRange : CameraNdcRange)
    {
        super(Projection, _origin, _ndcRange);
        
        fov    = _fov;
        aspect = _aspect;
        near   = _near;
        far    = _far;

        rebuildCameraMatrices();
    }

    public function update(_dt : Float)
    {
        rebuildCameraMatrices();
    }

    override function rebuildCameraMatrices()
    {
        switch ndcRandge
        {
            case ZeroToNegativeOne:
                projection.makeHeterogeneousPerspective(fov, aspect, near, far);
            case NegativeOneToNegativeOne:
                projection.makeHomogeneousPerspective(fov, aspect, near, far);
        }

        switch screenOrigin
        {
            case BottomLeft:
                projection.scale(perspectiveYFlipVector);
            case _:
        }

        view.copy(transformation.world.matrix).invert();
    }
}
