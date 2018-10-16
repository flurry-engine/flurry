package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;

typedef UserConfig = {};

class Main extends Flurry
{

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = GL45;

        _config.resources.preload.images.push({ id : 'assets/images/shapes.png' });
        _config.resources.preload.texts.push({ id : 'assets/images/shapes.atlas' });
        _config.resources.preload.shaders.push({
            id    : 'assets/shaders/textured.json',
            hlsl  : { vertex: 'assets/shaders/hlsl/textured.hlsl' , fragment: 'assets/shaders/hlsl/textured.hlsl' },
            gl45  : { vertex: 'assets/shaders/gl45/textured.vert' , fragment: 'assets/shaders/gl45/textured.frag' },
            webgl : { vertex: 'assets/shaders/webgl/textured.vert', fragment: 'assets/shaders/webgl/textured.frag' }
        });

        return _config;
    }

    /**
     * Once snow is ready we can create our engine instances and load a parcel with some default assets.
     */
    override function onReady()
    {
        // Setup a default root scene, in the future users will specify their root scene.
        root = new TetrisScene('root', app, null, renderer, resources, null);
        root.resumeOnCreation = true;
        root.create();
    }

    /**
     * Simulate all of the engines components.
     * @param _dt 
     */
    override function onUpdate(_dt : Float)
    {
        root.update(_dt);
    }
}