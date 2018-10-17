package;

import buddy.*;

typedef UserConfig = {};

class Main extends snow.App
{
    public function new() {}

    override function ready()
    {
        var runner = new SuitesRunner([
            new tests.api.maths.MathsTests(),
            new tests.api.maths.VectorTests(),
            new tests.api.maths.QuaternionTests(),
            new tests.api.maths.MatrixTests(),
            new tests.api.maths.RectangleTests(),
            new tests.api.maths.CircleTests(),
            
            new tests.api.importers.bmfont.BitmapFontParserTests(),
            new tests.api.importers.textureatlas.TextureAtlasParserTests(),

            new tests.api.gpu.batcher.BatcherTests(),
            new tests.api.gpu.geometry.VertexTests(),
            new tests.api.gpu.geometry.GeometryTests(),
            new tests.api.gpu.geometry.ColorTests(),
            new tests.api.gpu.geometry.shapes.ArcGeometryTests(),
            new tests.api.gpu.geometry.shapes.LineGeometryTests(),
            new tests.api.gpu.geometry.shapes.RingGeometryTests(),
            new tests.api.gpu.geometry.shapes.QuadGeometryTests(),
            new tests.api.gpu.geometry.shapes.TextGeometryTests(),
            new tests.api.gpu.geometry.shapes.CircleGeometryTests(),
            new tests.api.gpu.geometry.shapes.QuadPackGeometryTests(),
            new tests.api.gpu.geometry.shapes.RectangleGeometryTests(),

            new tests.modules.scene.SceneTests()
        ], new ColorReporter());

        runner.run();

        app.shutdown();
    }
}
