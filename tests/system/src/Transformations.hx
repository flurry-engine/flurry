package;

import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class Transformations extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.renderer.backend = Ogl3;

        _config.resources.preload.shaders = [
            {
                id   : 'textured',
                path : 'assets/shaders/textured.json',
                ogl3 : { fragment : 'assets/shaders/ogl3/textured.frag', vertex : 'assets/shaders/ogl3/textured.vert' },
                ogl4 : { fragment : 'assets/shaders/ogl4/textured.frag', vertex : 'assets/shaders/ogl4/textured.vert' },
                hlsl : { fragment : 'assets/shaders/hlsl/textured.hlsl', vertex : 'assets/shaders/hlsl/textured.hlsl' }
            }
        ];
        _config.resources.preload.images = [
            { id : 'tank1', path: 'assets/images/tank1.png' },
            { id : 'tank2', path: 'assets/images/tank2.png' },
            { id : 'tank3', path: 'assets/images/tank3.png' }
        ];

        return _config;
    }

    override function onReady()
    {
        var camera  = new Camera2D(display.width, display.height);
        var batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        var g1 = new QuadGeometry({ textures : [ resources.get('tank1', ImageResource) ], batchers : [ batcher ] });
        var g2 = new QuadGeometry({ textures : [ resources.get('tank2', ImageResource) ], batchers : [ batcher ] });
        var g3 = new QuadGeometry({ textures : [ resources.get('tank3', ImageResource) ], batchers : [ batcher ] });

        g1.origin.set_xy(128, 128);
        g2.origin.set_xy(128, 128);
        g3.origin.set_xy(128, 128);

        g1.position.set_xy(128, 256);
        g2.position.set_xy(384, 256);
        g3.position.set_xy(640, 256);

        g1.scale.set_xy(1.25, 1.25);
        g2.rotation.setFromAxisAngle(new Vector(0, 0, 1), Maths.toRadians( 45));
        g3.rotation.setFromAxisAngle(new Vector(0, 0, 1), Maths.toRadians(-66));
        g3.scale.set_xy(0.75, 0.75);
    }
}
