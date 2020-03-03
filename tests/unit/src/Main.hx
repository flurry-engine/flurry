
import buddy.Buddy;

class Main implements Buddy<[
    tests.api.maths.MathsTests,
    tests.api.maths.Vector4Tests,
    tests.api.maths.Vector3Tests,
    tests.api.maths.Vector2Tests,
    tests.api.maths.QuaternionTests,
    tests.api.maths.MatrixTests,
    tests.api.maths.RectangleTests,
    tests.api.maths.CircleTests,
    tests.api.maths.SpatialTests,
    tests.api.maths.TransformationTests,

    tests.api.buffers.Float32BufferDataTests,
    tests.api.buffers.UInt16BufferDataTests,

    tests.api.display.DisplayTests,

    tests.api.importers.bmfont.BitmapFontParserTests,
    tests.api.importers.textureatlas.TextureAtlasParserTests,

    tests.api.input.InputTests,

    tests.api.gpu.geometry.BlendingTests,
    tests.api.gpu.geometry.GeometryTests,
    tests.api.gpu.geometry.VertexBlobTests,
    tests.api.gpu.geometry.IndexBlobTests,
    tests.api.gpu.geometry.UniformBlobTests,
    tests.api.gpu.geometry.shapes.QuadGeometryTests,
    tests.api.gpu.geometry.shapes.TextGeometryTests,
    tests.api.gpu.batcher.BatcherStateTests,
    tests.api.gpu.batcher.BatcherTests,

#if (target.threaded)

    tests.api.resources.ResourceSystemTests,

#end

    tests.modules.differ.shapes.CircleTests,
    tests.modules.differ.shapes.PolygonTests,
    tests.modules.differ.shapes.RayTests,

    tests.modules.differ.sat.SAT2DTests,

    tests.modules.differ.data.RayCollisionTests,
    tests.modules.differ.data.RayIntersectionTests,
    tests.modules.differ.data.ShapeCollisionTests,
]>
{
    //
}
