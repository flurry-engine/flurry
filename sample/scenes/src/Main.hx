package;

import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.modules.scene.Scene;

typedef UserConfig = {};

class Main extends Flurry
{
    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = GL45;

        _config.resources.preload.parcels.push('assets/parcels/sample.parcel');

        return _config;
    }

    override function onReady()
    {
        root = createTree();
        root.resumeOnCreation = true;
        root.create();
    }

    override function onUpdate(_dt : Float)
    {
        root.update(_dt);
    }

    /**
     * Create a complex scene tree to ensure everything is working as planned.
     * @return Scene
     */
    function createTree() : Scene
    {
        var rootNode = new Scene('root', app, null, renderer, resources, events);
        var child1   = rootNode.addChild(Scene, 'root/child1');
        rootNode.addChild(Scene, 'root/child2');
        rootNode.addChild(Scene, 'root/child3');
        rootNode.addChild(Scene, 'root/child4');

        child1.addChild(Scene, 'root/child1/child1');
        child1.addChild(Scene, 'root/child1/child2').addChild(TestScene, 'root/child1/child2/child1');

        return rootNode;
    }
}
