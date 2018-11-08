package;

import snow.Snow;
import uk.aidanlee.flurry.api.EventBus;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.gpu.camera.OrthographicCamera;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.modules.scene.Scene;

class SampleScene extends Scene
{
    /**
     * Batcher to store all of our quad geometry.
     */
    var batcher : Batcher;

    /**
     * 2D camera to view all our geometries.
     */
    var camera : OrthographicCamera;

    /**
     * Number of haxe logos to create.
     */
    var numLogos : Int;

    /**
     * Array of all our haxe logos.
     */
    var sprites : Array<QuadGeometry>;

    /**
     * Array of all our haxe logos direction unit vector.
     */
    var vectors : Array<Vector>;

    public function new(_name : String, _snow : Snow, _parent : Scene, _renderer : Renderer, _resources : ResourceSystem, _events : EventBus)
    {
        super(_name, _snow, _parent, _renderer, _resources, _events);
    }

    override function onResumed<T>(_data : T = null)
    {
        camera  = new OrthographicCamera(1600, 900);
        batcher = renderer.createBatcher({ shader : resources.get('std-shader-textured.json', ShaderResource), camera : camera });

        // Add some sprites.
        sprites  = [];
        vectors  = [];
        numLogos = 10000;
        for (i in 0...numLogos)
        {
            var sprite = new QuadGeometry({
                textures : [ resources.get('assets/images/haxe.png', ImageResource) ],
                batchers : [ batcher ]
            });
            sprite.origin.set_xy(75, 75);
            sprite.position.set_xy(1600 / 2, 900 / 2);

            sprites.push(sprite);
            vectors.push(random_point_in_unit_circle());
        }

        var logo = new QuadGeometry({
            textures   : [ resources.get('assets/images/logo.png', ImageResource) ],
            batchers   : [ batcher ],
            depth      : 2
        });
        logo.origin.set_xy(resources.get('assets/images/logo.png', ImageResource).width / 2, resources.get('assets/images/logo.png', ImageResource).height / 2);
        logo.position.set_xy(1600 / 2, 900 / 2);
    }

    override function onUpdate(_dt : Float)
    {
        // Make all of our haxe logos bounce around the screen.
        for (i in 0...numLogos)
        {
            sprites[i].position.x += (vectors[i].x * 1000) * _dt;
            sprites[i].position.y += (vectors[i].y * 1000) * _dt;
            
            if (sprites[i].position.x > 1600 + sprites[i].origin.x) vectors[i].x = -vectors[i].x;
            if (sprites[i].position.x <     0) vectors[i].x = -vectors[i].x;
            if (sprites[i].position.y >  900 + sprites[i].origin.y) vectors[i].y = -vectors[i].y;
            if (sprites[i].position.y <    0)  vectors[i].y = -vectors[i].y;
        }

        super.onUpdate(_dt);
    }

    override function onPaused<T>(_data : T = null)
    {
        // TODO : Clean up geometry.
    }

    /**
     * Create a random unit vector.
     * @return Vector
     */
    function random_point_in_unit_circle() : Vector
    {
        var r : Float = Math.sqrt(Math.random());
        var t : Float = (-1 + (2 * Math.random())) * (Math.PI * 2);

        return new Vector(r * Math.cos(t), r * Math.sin(t));
    }
}
