package;

import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.camera.Camera3D;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.Vertex;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.Flurry;

class StencilTesting extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'System Tests';
        _config.window.width  = 768;
        _config.window.height = 512;

        _config.resources.preload.shaders = [
            {
                id   : 'textured',
                path : 'assets/shaders/textured.json',
                ogl3 : { fragment : 'assets/shaders/ogl3/textured.frag', vertex : 'assets/shaders/ogl3/textured.vert' },
                ogl4 : { fragment : 'assets/shaders/ogl4/textured.frag', vertex : 'assets/shaders/ogl4/textured.vert' },
                hlsl : { fragment : 'assets/shaders/hlsl/textured.hlsl', vertex : 'assets/shaders/hlsl/textured.hlsl' }
            },
            {
                id   : 'purple',
                path : 'assets/shaders/textured.json',
                ogl3 : { fragment : 'assets/shaders/ogl3/purple.frag', vertex : 'assets/shaders/ogl3/textured.vert' },
                ogl4 : { fragment : 'assets/shaders/ogl4/purple.frag', vertex : 'assets/shaders/ogl4/textured.vert' },
                hlsl : { fragment : 'assets/shaders/hlsl/purple.hlsl', vertex : 'assets/shaders/hlsl/purple.hlsl' }
            }
        ];
        _config.resources.preload.images = [
            { id : 'wood' , path: 'assets/images/wood.png' }
        ];

        return _config;
    }

    override function onReady()
    {
        var camera = new Camera3D(45, display.width / display.height, 0.1, 100);
        camera.transformation.position.set_xyz(0, 0, 3);

        var batcher1 = renderer.createBatcher({
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

        var batcher2 = renderer.createBatcher({
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

        var positions = [
            new Vector( 0.0,  0.0,   0.0),
            new Vector( 2.0,  5.0, -15.0),
            new Vector(-1.5, -2.2, - 2.5),
            new Vector(-3.8, -2.0, -12.3),
            new Vector( 2.4, -0.4, - 3.5),
            new Vector(-1.7,  3.0, - 7.5),
            new Vector( 1.3, -2.0, - 2.5),
            new Vector( 1.5,  2.0, - 2.5),
            new Vector( 1.5,  0.2, - 1.5),
            new Vector(-1.3,  1.0, - 1.5)
        ];

        var cubes1 = [ for (i in 0...10) cube(batcher1) ];
        var cubes2 = [ for (i in 0...10) cube(batcher2) ];

        for (i in 0...positions.length)
        {
            cubes1[i].rotation.setFromAxisAngle(new Vector(1.0, 0.3, 0.5), Maths.toRadians(20 * i));
            cubes1[i].position.copyFrom(positions[i]);

            cubes2[i].rotation.setFromAxisAngle(new Vector(1.0, 0.3, 0.5), Maths.toRadians(20 * i));
            cubes2[i].position.copyFrom(positions[i]);
            cubes2[i].scale.set_xy(1.2, 1.2);
        }
    }

    function cube(_batcher : Batcher) : Geometry
    {
        return new Geometry({
            batchers : [ _batcher ],
            textures : [ resources.get('wood', ImageResource) ],
            vertices : [
                new Vertex( new Vector(-0.5, -0.5, -0.5), new Color(), new Vector(0.0, 0.0)),
                new Vertex( new Vector( 0.5, -0.5, -0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector( 0.5,  0.5, -0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector( 0.5,  0.5, -0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector(-0.5,  0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector(-0.5, -0.5, -0.5), new Color(), new Vector(0.0, 0.0)),

                new Vertex( new Vector(-0.5, -0.5,  0.5), new Color(), new Vector(0.0, 0.0)),
                new Vertex( new Vector( 0.5, -0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector( 0.5,  0.5,  0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector( 0.5,  0.5,  0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector(-0.5,  0.5,  0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector(-0.5, -0.5,  0.5), new Color(), new Vector(0.0, 0.0)),

                new Vertex( new Vector(-0.5,  0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector(-0.5,  0.5, -0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector(-0.5, -0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector(-0.5, -0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector(-0.5, -0.5,  0.5), new Color(), new Vector(0.0, 0.0)),
                new Vertex( new Vector(-0.5,  0.5,  0.5), new Color(), new Vector(1.0, 0.0)),

                new Vertex( new Vector( 0.5,  0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector( 0.5,  0.5, -0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector( 0.5, -0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector( 0.5, -0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector( 0.5, -0.5,  0.5), new Color(), new Vector(0.0, 0.0)),
                new Vertex( new Vector( 0.5,  0.5,  0.5), new Color(), new Vector(1.0, 0.0)),

                new Vertex( new Vector(-0.5, -0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector( 0.5, -0.5, -0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector( 0.5, -0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector( 0.5, -0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector(-0.5, -0.5,  0.5), new Color(), new Vector(0.0, 0.0)),
                new Vertex( new Vector(-0.5, -0.5, -0.5), new Color(), new Vector(0.0, 1.0)),

                new Vertex( new Vector(-0.5,  0.5, -0.5), new Color(), new Vector(0.0, 1.0)),
                new Vertex( new Vector( 0.5,  0.5, -0.5), new Color(), new Vector(1.0, 1.0)),
                new Vertex( new Vector( 0.5,  0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector( 0.5,  0.5,  0.5), new Color(), new Vector(1.0, 0.0)),
                new Vertex( new Vector(-0.5,  0.5,  0.5), new Color(), new Vector(0.0, 0.0)),
                new Vertex( new Vector(-0.5,  0.5, -0.5), new Color(), new Vector(0.0, 1.0))
            ]
        });
    }
}
