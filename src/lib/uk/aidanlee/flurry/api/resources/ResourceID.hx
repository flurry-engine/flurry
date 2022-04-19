package uk.aidanlee.flurry.api.resources;

abstract ResourceID(Int) to Int
{
    public static final invalid = new ResourceID(-1);

    public function new(_val)
    {
        this = _val;
    }
}