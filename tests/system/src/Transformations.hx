package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class Transformations extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = [ 'preload', 'shaders' ];

        return _config;
    }

    override function onReady()
    {
        final axis    = new Vector3(0, 0, 1);
        final camera  = renderer.createCamera2D(display.width, display.height);
        final batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        final g1 = new QuadGeometry({ texture : resources.get('tank1', ImageFrameResource), batchers : [ batcher ] });
        final g2 = new QuadGeometry({ texture : resources.get('tank2', ImageFrameResource), batchers : [ batcher ] });
        final g3 = new QuadGeometry({ texture : resources.get('tank3', ImageFrameResource), batchers : [ batcher ] });

        g1.origin.set_xy(128, 128);
        g2.origin.set_xy(128, 128);
        g3.origin.set_xy(128, 128);

        g1.position.set_xy(128, 256);
        g2.position.set_xy(384, 256);
        g3.position.set_xy(640, 256);

        g1.scale.set_xy(1.25, 1.25);
        g2.rotation.setFromAxisAngle(axis, Maths.toRadians( 45));
        g3.rotation.setFromAxisAngle(axis, Maths.toRadians(-66));
        g3.scale.set_xy(0.75, 0.75);
    }
}
