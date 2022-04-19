package uk.aidanlee.flurry.api.gpu.drawing;

import uk.aidanlee.flurry.api.gpu.geometry.Geometry;

inline function drawGeometry(_ctx : GraphicsContext, _geometry : Geometry)
{
    for (idx => input in _geometry.inputs)
    {
        switch input.type
        {
            case Left(page):
                _ctx.usePage(idx, page, input.sampler);
            case Right(surface):
                _ctx.useSurface(idx, surface, input.sampler);
        }
    }

    for (blob in _geometry.uniforms)
    {
        _ctx.useUniformBlob(blob);
    }

    _ctx.prepare();

    _ctx.vtxOutput.write(_geometry.vtxBlob);
    _ctx.idxOutput.write(_geometry.idxBlob);
}