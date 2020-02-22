package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob.VertexBlobBuilder;

class DepthTesting extends Flurry
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
        camera.update(0);

        final batcher = renderer.createBatcher({
            shader : resources.get('textured', ShaderResource),
            camera : camera,
            depthOptions : {
                depthTesting: true,
                depthMasking: true,
                depthFunction: LessThan
            }
        });

        final cube = UnIndexed(new VertexBlobBuilder()
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

        final cubes = [ for (_ in 0...10) new Geometry({
            batchers : [ batcher ],
            textures : Textures([ resources.get('wood', ImageResource) ]),
            data     : cube
        }) ];

        for (i in 0...positions.length)
        {
            cubes[i].rotation.setFromAxisAngle(axis, Maths.toRadians(20 * i));
            cubes[i].position.copyFrom(positions[i]);
        }
    }
}
