package uk.aidanlee.flurry.api.gpu.surfaces;

abstract SurfaceID(Int) to Int
{
    public static final invalid = new SurfaceID(-1);

    public static final backbuffer = new SurfaceID(0);

    public function new(_val)
    {
        this = _val;
    }
}