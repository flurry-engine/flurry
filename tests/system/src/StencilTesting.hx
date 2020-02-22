package;

import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class StencilTesting extends Flurry
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
        final camera = renderer.createCamera3D(45, display.width / display.height, 0.1, 100);
        camera.transformation.position.set(0, 0, 3);

        final batcher1 = renderer.createBatcher({
            shader : resources.get('textured', ShaderResource),
            camera : camera,
            depthOptions : {
                depthTesting: true,
                depthMasking: true,
                depthFunction: LessThan
            },
            stencilOptions: {
                stencilTesting: true,

                stencilFrontMask: 0xff,
                stencilFrontFunction: Always,
                stencilFrontTestFail: Keep,
                stencilFrontDepthTestFail: Keep,
                stencilFrontDepthTestPass: Keep,

                stencilBackMask: 0xff,
                stencilBackFunction: Always,
                stencilBackTestFail: Keep,
                stencilBackDepthTestFail: Keep,
                stencilBackDepthTestPass: Keep
            }
        });

        final batcher2 = renderer.createBatcher({
            shader : resources.get('purple', ShaderResource),
            camera : camera,
            depthOptions : {
                depthTesting: false,
                depthMasking: true,
                depthFunction: LessThan
            },
            stencilOptions: {
                stencilTesting: true,

                stencilFrontMask: 0x00,
                stencilFrontFunction: Always,
                stencilFrontTestFail: Keep,
                stencilFrontDepthTestFail: Keep,
                stencilFrontDepthTestPass: Keep,

                stencilBackMask: 0x00,
                stencilBackFunction: Always,
                stencilBackTestFail: Keep,
                stencilBackDepthTestFail: Keep,
                stencilBackDepthTestPass: Keep
            }
        });

        final data = UnIndexed(new VertexBlobBuilder()
            .addFloat3(-0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)
            .addFloat3( 0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3( 0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3( 0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3(-0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3(-0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)

            .addFloat3(-0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)
            .addFloat3( 0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3( 0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3( 0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3(-0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3(-0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)

            .addFloat3(-0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3(-0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3(-0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3(-0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3(-0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)
            .addFloat3(-0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)

            .addFloat3( 0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3( 0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3( 0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3( 0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3( 0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)
            .addFloat3( 0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)

            .addFloat3(-0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3( 0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3( 0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3( 0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3(-0.5, -0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)
            .addFloat3(-0.5, -0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)

            .addFloat3(-0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)
            .addFloat3( 0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 1.0)
            .addFloat3( 0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3( 0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(1.0, 0.0)
            .addFloat3(-0.5,  0.5,  0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 0.0)
            .addFloat3(-0.5,  0.5, -0.5).addFloat4(1, 1, 1, 1).addFloat2(0.0, 1.0)

            .vertexBlob());

        final axis      = new Vector3(1.0, 0.3, 0.5);
        final positions = [
            new Vector3( 0.0,  0.0,   0.0),
            new Vector3( 2.0,  5.0, -15.0),
            new Vector3(-1.5, -2.2, - 2.5),
            new Vector3(-3.8, -2.0, -12.3),
            new Vector3( 2.4, -0.4, - 3.5),
            new Vector3(-1.7,  3.0, - 7.5),
            new Vector3( 1.3, -2.0, - 2.5),
            new Vector3( 1.5,  2.0, - 2.5),
            new Vector3( 1.5,  0.2, - 1.5),
            new Vector3(-1.3,  1.0, - 1.5)
        ];

        final cubes1 = [ for (_ in 0...10) cube(batcher1, data) ];
        final cubes2 = [ for (_ in 0...10) cube(batcher2, data) ];

        for (i in 0...positions.length)
        {
            cubes1[i].rotation.setFromAxisAngle(axis, Maths.toRadians(20 * i));
            cubes1[i].position.copyFrom(positions[i]);

            cubes2[i].rotation.setFromAxisAngle(axis, Maths.toRadians(20 * i));
            cubes2[i].position.copyFrom(positions[i]);
            cubes2[i].scale.set_xy(1.2, 1.2);
        }
    }

    function cube(_batcher : Batcher, _data : GeometryData) : Geometry
    {
        return new Geometry({
            batchers : [ _batcher ],
            textures : Textures([ resources.get('wood', ImageResource) ]),
            data     : _data
        });
    }
}
