package;

import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class ShaderUniforms extends Flurry
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
        var u1 = new Uniforms();
        u1.float.set('red'  , 1.0);
        u1.float.set('green', 1.0);
        u1.float.set('blue' , 1.0);

        var u2 = new Uniforms();
        u2.float.set('red'  , 1.0);
        u2.float.set('green', 0.5);
        u2.float.set('blue' , 0.5);

        var u3 = new Uniforms();
        u3.float.set('red'  , 0.5);
        u3.float.set('green', 0.5);
        u3.float.set('blue' , 1.0);

        var camera  = new Camera2D(display.width, display.height);
        var batcher = renderer.createBatcher({ shader : resources.get('colourise', ShaderResource), camera : camera });

        new QuadGeometry({ textures : [ resources.get('tank1', ImageResource) ], batchers : [ batcher ], uniforms : u1 }).position.set_xy(  0, 128);
        new QuadGeometry({ textures : [ resources.get('tank2', ImageResource) ], batchers : [ batcher ], uniforms : u2 }).position.set_xy(256, 128);
        new QuadGeometry({ textures : [ resources.get('tank3', ImageResource) ], batchers : [ batcher ], uniforms : u3 }).position.set_xy(512, 128);
    }
}
