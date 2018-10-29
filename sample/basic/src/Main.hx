package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.camera.OrthographicCamera;
import uk.aidanlee.flurry.api.gpu.camera.Camera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;

typedef UserConfig = {};

class Main extends Flurry
{
    var camera : Camera;

    var batcher : Batcher;

    var image : QuadGeometry;

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = WEBGL;

        _config.resources.preload.parcels.push('assets/parcels/sample.parcel');

        return _config;
    }

    override function onReady()
    {
        camera  = new OrthographicCamera(1600, 900);
        batcher = renderer.createBatcher({ shader : resources.get('std-shader-textured.json', ShaderResource), camera : camera });
        image   = new QuadGeometry({ batchers : [ batcher ], textures : [ resources.get('assets/images/haxe.png', ImageResource) ] });
    }
}
