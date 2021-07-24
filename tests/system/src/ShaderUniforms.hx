package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.maths.Vector4;
import uk.aidanlee.flurry.api.gpu.geometry.UniformBlob;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Parcels.Preload;
import uk.aidanlee.flurry.api.resources.Parcels.Shaders;

class ShaderUniforms extends Flurry
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
        final u1 = new UniformBlobBuilder("colours")
            .addVector4('colour', new Vector4(1.0, 1.0, 1.0, 1.0))
            .uniformBlob();

        final u2 = new UniformBlobBuilder("colours")
            .addVector4('colour', new Vector4(1.0, 0.5, 0.5, 1.0))
            .uniformBlob();

        final u3 = new UniformBlobBuilder("colours")
            .addVector4('colour', new Vector4(0.5, 0.5, 1.0, 1.0))
            .uniformBlob();

        final camera  = renderer.createCamera2D(display.width, display.height);
        final batcher = renderer.createBatcher({ shader : Shaders.colourise, camera : camera });

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank1),
            batchers : [ batcher ],
            shader   : Some(Shaders.colourise),
            uniforms : Some([ u1 ]),
            x : 0, y : 128, width : 256, height : 256
        }).position.set_xy(  0, 128);

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank2),
            batchers : [ batcher ],
            shader   : Some(Shaders.colourise),
            uniforms : Some([ u2 ]),
            x : 256, y : 128, width : 256, height : 256
        });

        new QuadGeometry({
            texture  : cast resources.get(Preload.tank3),
            batchers : [ batcher ],
            shader   : Some(Shaders.colourise),
            uniforms : Some([ u3 ]),
            x : 512, y : 128, width : 256, height : 256
        });
    }
}
