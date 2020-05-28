package;

import haxe.io.Bytes;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;

class RenderTarget extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload = 'preload';

        return _config;
    }

    override function onReady()
    {
        resources.addResource(new ImageResource('surface', 256, 256, Bytes.alloc(256 * 256 * 4)));
        resources.addResource(new ImageFrameResource('surface_frame', 'surface', 0, 0, 256, 256, 0, 0, 1, 1));

        final camera1  = renderer.createCamera2D(display.width, display.height);
        final camera2  = renderer.createCamera2D(256, 256);
        final batcher1 = renderer.createBatcher({
            shader : resources.get('textured', ShaderResource),
            camera : camera1
        });
        final batcher2 = renderer.createBatcher({
            shader : resources.get('textured', ShaderResource),
            camera : camera2,
            target : Texture(resources.get('surface', ImageResource))
        });

        // Drawn to target
        new QuadGeometry({
            texture  : resources.get('tank3', ImageFrameResource),
            batchers : [ batcher2 ],
            x : 0, y : 0, width : 256, height : 256
        });

        // Drawn to backbuffer
        new QuadGeometry({
            texture  : resources.get('tank1', ImageFrameResource),
            batchers : [ batcher1 ],
            x : 0, y : 128, width : 256, height : 256
        });
        new QuadGeometry({
            texture  : resources.get('tank2', ImageFrameResource),
            batchers : [ batcher1 ],
            x : 256, y : 128, width : 256, height : 256
        });
        new QuadGeometry({
            texture  : resources.get('surface_frame', ImageFrameResource),
            batchers : [ batcher1 ],
            x : 512, y : 128, width : 256, height : 256
        });
    }
}
