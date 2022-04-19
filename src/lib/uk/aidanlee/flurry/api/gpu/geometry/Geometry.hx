package uk.aidanlee.flurry.api.gpu.geometry;

import haxe.ds.Either;
import haxe.ds.ReadOnlyArray;
import uk.aidanlee.flurry.api.gpu.shaders.UniformBlob;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.ResourceID;

class Geometry
{
    public final vtxBlob : VertexBlob;

    public final idxBlob : IndexBlob;

    public final inputs : ReadOnlyArray<GeometryInput>;

    public final uniforms : ReadOnlyArray<UniformBlob>;

    public function new(_vtxBlob, _idxBlob, _inputs, _uniforms)
    {
        vtxBlob  = _vtxBlob;
        idxBlob  = _idxBlob;
        inputs   = _inputs;
        uniforms = _uniforms;
    }
}

class GeometryInput
{
    public final type : Either<ResourceID, SurfaceID>;

    public final sampler : SamplerState;

    public function new(_type, _sampler)
    {
        type    = _type;
        sampler = _sampler;
    }
}
