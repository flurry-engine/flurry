package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.gpu.geometry.Transformation;

class Camera3D extends Camera
{
    public final transformation : Transformation;

    public var fov (default, set) : Float;

    inline function set_fov(_v : Float) : Float
    {
        dirty = true;

        return fov = _v;
    }

    public var aspect (default, set) : Float;

    inline function set_aspect(_v : Float) : Float
    {
        dirty = true;

        return aspect = _v;
    }

    public var near (default, set) : Float;

    inline function set_near(_v : Float) : Float
    {
        dirty = true;

        return near = _v;
    }

    public var far (default, set) : Float;

    inline function set_far(_v : Float) : Float
    {
        dirty = true;

        return far = _v;
    }

    public var dirty : Bool;

    public function new(_fov : Float, _aspect : Float, _near : Float, _far : Float)
    {
        super(Projection);

        transformation = new Transformation();
        
        fov    = _fov;
        aspect = _aspect;
        near   = _near;
        far    = _far;
        dirty  = true;
    }

    public function update()
    {
        dirty = true;
    }
}
