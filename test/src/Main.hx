
import buddy.Buddy;

class Main implements Buddy<[
    tests.api.maths.MathsTests,
    tests.api.maths.VectorTests,
    tests.api.maths.QuaternionTests,
    tests.api.maths.MatrixTests,
    tests.api.maths.RectangleTests,
    tests.api.maths.CircleTests,

    tests.api.display.DisplayTests,

    tests.api.importers.bmfont.BitmapFontParserTests,
    tests.api.importers.textureatlas.TextureAtlasParserTests,

    tests.api.input.InputTests,

    tests.api.gpu.geometry.VertexTests,
    tests.api.gpu.geometry.TransformationTests,
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

    tests.api.EventBusTests
]>
{
    //
}
