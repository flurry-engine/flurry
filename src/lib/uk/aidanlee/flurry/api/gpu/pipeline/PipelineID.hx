package uk.aidanlee.flurry.api.gpu.pipeline;

abstract PipelineID(Int) to Int
{
    public static final invalid = new PipelineID(-1);

    public function new(_id)
    {
        this = _id;
    }
}