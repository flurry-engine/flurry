package;

import haxe.io.Bytes;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class RenderTarget extends Flurry
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
        resources.addResource(new ImageResource('surface', 256, 256, Bytes.alloc(256 * 256 * 4)));

        final camera1  = new Camera2D(display.width, display.height);
        final camera2  = new Camera2D(256, 256);
        final batcher1 = renderer.createBatcher({
            shader : resources.get('textured', ShaderResource),
            camera : camera1
        });
        final batcher2 = renderer.createBatcher({
            shader : resources.get('textured', ShaderResource),
            camera : camera2,
            target : Texture(resources.get('surface', ImageResource))
        });

        new QuadGeometry({
            textures : Textures([ resources.get('tank3', ImageResource) ]),
            batchers : [ batcher2 ],
            x : 0, y : 0, w : 256, h : 256
        });

        new QuadGeometry({
            textures : Textures([ resources.get('tank1', ImageResource) ]),
            batchers : [ batcher1 ],
            x : 0, y : 128, w : 256, h : 256
        });
        new QuadGeometry({
            textures : Textures([ resources.get('tank2', ImageResource) ]),
            batchers : [ batcher1 ],
            x : 256, y : 128, w : 256, h : 256
        });
        new QuadGeometry({
            textures : Textures([ resources.get('surface', ImageResource) ]),
            batchers : [ batcher1 ],
            x : 512, y : 128, w : 256, h : 256
        });
    }
}
