package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class Colourised extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = PrePackaged('preload');

        return _config;
    }

    override function onReady()
    {
        final camera  = new Camera2D(display.width, display.height);
        final batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        final g1 = new QuadGeometry({
            textures : Textures([ resources.get('tank1', ImageResource) ]),
            batchers : [ batcher ],
            x : 0, y : 128, w : 256, h : 256
        });
        final g2 = new QuadGeometry({
            textures : Textures([ resources.get('tank2', ImageResource) ]),
            batchers : [ batcher ],
            x : 256, y : 128, w : 256, h : 256
        });
        final g3 = new QuadGeometry({
            textures : Textures([ resources.get('tank3', ImageResource) ]),
            batchers : [ batcher ],
            x : 512, y : 129, w : 256, h : 256
        });

        setColour(g1, 1, 0, 0, 1);
        setColour(g2, 0, 1, 0, 1);
        setColour(g3, 0, 0, 1, 1);
    }

    function setColour(_geometry : QuadGeometry, _r : Float, _g : Float, _b : Float, _a : Float)
    {
        switch _geometry.data
        {
            case Indexed(_vertices, _):
                _vertices.floatAccess[3] = _r;
                _vertices.floatAccess[4] = _g;
                _vertices.floatAccess[5] = _b;
                _vertices.floatAccess[6] = _a;

                _vertices.floatAccess[12] = _r;
                _vertices.floatAccess[13] = _g;
                _vertices.floatAccess[14] = _b;
                _vertices.floatAccess[15] = _a;

                _vertices.floatAccess[21] = _r;
                _vertices.floatAccess[22] = _g;
                _vertices.floatAccess[23] = _b;
                _vertices.floatAccess[24] = _a;

                _vertices.floatAccess[30] = _r;
                _vertices.floatAccess[31] = _g;
                _vertices.floatAccess[32] = _b;
                _vertices.floatAccess[33] = _a;
            case _:
        }
    }
}
