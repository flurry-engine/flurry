package;

import buddy.*;

typedef UserConfig = {};

class Main extends snow.App
{
    public function new() {}

    override function ready()
    {
        var runner = new SuitesRunner([
            new tests.maths.MathsTests(),
            new tests.maths.VectorTests(),
            new tests.maths.QuaternionTests(),
            new tests.maths.MatrixTests(),
            new tests.maths.RectangleTests(),
            new tests.maths.CircleTests(),
            
            new tests.importers.bmfont.BitmapFontParserTests(),
            new tests.importers.textureatlas.TextureAtlasParserTests(),

            new tests.gpu.batcher.BatcherTests(),
            new tests.gpu.geometry.VertexTests(),
            new tests.gpu.geometry.GeometryTests(),
            new tests.gpu.geometry.ColorTests(),
            new tests.gpu.geometry.shapes.ArcGeometryTests(),
            new tests.gpu.geometry.shapes.LineGeometryTests(),
            new tests.gpu.geometry.shapes.RingGeometryTests(),
            new tests.gpu.geometry.shapes.QuadGeometryTests(),
            new tests.gpu.geometry.shapes.TextGeometryTests(),
            new tests.gpu.geometry.shapes.CircleGeometryTests(),
            new tests.gpu.geometry.shapes.QuadPackGeometryTests(),
            new tests.gpu.geometry.shapes.RectangleGeometryTests(),

            new tests.scene.SceneTests()
        ], new ColorReporter());

        runner.run();

        app.shutdown();
    }
}
