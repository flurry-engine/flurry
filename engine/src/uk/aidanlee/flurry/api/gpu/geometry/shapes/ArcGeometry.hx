package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.geometry.shapes.CircleGeometry.CircleGeometryOptions;

class ArcGeometry extends RingGeometry
{
    public function new(_options : CircleGeometryOptions)
    {
        super(_options);

        vertices.pop();
        vertices.pop();
    }
}
