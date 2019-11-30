
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

    tests.api.gpu.geometry.VertexTests,
    tests.api.gpu.geometry.VertexBlobTests,
    tests.api.gpu.geometry.BlendingTests,
    tests.api.gpu.geometry.ColorTests,
    tests.api.gpu.geometry.GeometryTests,
    tests.api.gpu.geometry.shapes.ArcGeometryTests,
    tests.api.gpu.geometry.shapes.CircleGeometryTests,
    tests.api.gpu.geometry.shapes.LineGeometryTests,
    tests.api.gpu.geometry.shapes.QuadGeometryTests,
    tests.api.gpu.geometry.shapes.QuadPackGeometryTests,
    tests.api.gpu.geometry.shapes.RectangleGeometryTests,
    tests.api.gpu.geometry.shapes.RingGeometryTests,
    tests.api.gpu.geometry.shapes.TextGeometryTests,
    tests.api.gpu.batcher.BatcherStateTests,
    tests.api.gpu.batcher.BatcherTests,

    tests.api.resources.ResourceSystemTests,

    tests.api.thread.JobQueueTests,

    tests.api.EventBusTests,

    tests.modules.differ.shapes.CircleTests,
    tests.modules.differ.shapes.PolygonTests,
    tests.modules.differ.shapes.RayTests,

    tests.modules.differ.sat.SAT2DTests,

    tests.modules.differ.data.RayCollisionTests,
    tests.modules.differ.data.RayIntersectionTests,
    tests.modules.differ.data.ShapeCollisionTests,

    tests.utils.bytes.BytesPackerTests
]>
{
    //
}
