package uk.aidanlee.flurry.api.gpu;

abstract SurfaceID(Int) to Int
{
    public static final backbuffer = new SurfaceID(0);

    public function new(_val)
    {
        this = _val;
    }
}