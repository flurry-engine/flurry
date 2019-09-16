package;

import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class ImageSamplers extends Flurry
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
        var camera  = new Camera2D(display.width, display.height);
        var batcher = renderer.createBatcher({ shader : resources.get('textured', ShaderResource), camera : camera });

        var g1 = new QuadGeometry({
            textures : [ resources.get('van', ImageResource) ],
            batchers : [ batcher ] });
        g1.position.set_xy(256, 128);
        g1.scale.set_xy(2, 2);

        var g2 = new QuadGeometry({
            textures : [ resources.get('van', ImageResource) ],
            samplers : [ new SamplerState(Wrap, Wrap, Nearest, Nearest) ],
            batchers : [ batcher ] });
        g2.position.set_xy(384, 128);
        g2.scale.set_xy(2, 2);

        var g3 = new QuadGeometry({
            textures : [ resources.get('van', ImageResource) ],
            samplers : [ new SamplerState(Mirror, Mirror, Linear, Linear) ],
            batchers : [ batcher ] });
        g3.position.set_xy(256, 256);
        g3.scale.set_xy(2, 2);
        for (v in g3.vertices) v.texCoord.multiplyScalar(2);

        var g4 = new QuadGeometry({
            textures : [ resources.get('van', ImageResource) ],
            samplers : [ new SamplerState(Wrap, Wrap, Linear, Linear) ],
            batchers : [ batcher ] });
        g4.position.set_xy(384, 256);
        g4.scale.set_xy(2, 2);
        for (v in g4.vertices) v.texCoord.multiplyScalar(2);
    }
}
