
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.camera.OrthographicCamera;
import uk.aidanlee.flurry.modules.imgui.ImGuiImpl;
import imgui.ImGui;
import imgui.util.ImVec2;

typedef UserConfig = {};

class Main extends Flurry
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

    /**
     * Imgui implementation helper.
     */
    var imgui : ImGuiImpl;

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = GLES;

        _config.resources.preload.parcels.push('assets/parcels/sample.parcel');

        return _config;
    }

    override function onReady()
    {
        imgui   = new ImGuiImpl(this);
        camera  = new OrthographicCamera(1600, 900);
        batcher = renderer.createBatcher({ shader : resources.get('std-shader-textured.json', ShaderResource), camera : camera });

        // Add some sprites.
        var largeHaxe = 'assets/images/haxe.png';
        var smallHaxe = 'assets/images/logo.png';

        sprites  = [];
        vectors  = [];
        numLogos = 10000;
        for (i in 0...numLogos)
        {
            var sprite = new QuadGeometry({
                textures : [ resources.get(largeHaxe, ImageResource) ],
                batchers : [ batcher ]
            });
            sprite.origin.set_xy(75, 75);
            sprite.position.set_xy(1600 / 2, 900 / 2);

            sprites.push(sprite);
            vectors.push(random_point_in_unit_circle());
        }

        var logo = new QuadGeometry({
            textures   : [ resources.get(smallHaxe, ImageResource) ],
            batchers   : [ batcher ],
            depth      : 2,
            unchanging : true
        });
        logo.origin.set_xy(resources.get(smallHaxe, ImageResource).width / 2, resources.get(smallHaxe, ImageResource).height / 2);
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
    }

    override function onPostUpdate()
    {
        uiShowRenderStats();
    }

    /**
     * Draw some stats about the renderer.
     */
    function uiShowRenderStats()
    {
        var distance       = 10;
        var windowPos      = ImVec2.create(ImGui.getIO().displaySize.x - distance, distance);
        var windowPosPivot = ImVec2.create(1, 0);

        ImGui.setNextWindowPos(windowPos, ImGuiCond.Always, windowPosPivot);
        ImGui.setNextWindowBgAlpha(0.3);
        if (ImGui.begin('Render Stats', NoMove | NoTitleBar | NoResize | AlwaysAutoResize | NoSavedSettings | NoFocusOnAppearing | NoNav))
        {
            ImGui.text('total batchers   ${renderer.stats.totalBatchers}');
            ImGui.text('total geometry   ${renderer.stats.totalGeometry}');
            ImGui.text('total vertices   ${renderer.stats.totalVertices}');
            ImGui.text('dynamic draws    ${renderer.stats.dynamicDraws}');
            ImGui.text('unchanging draws ${renderer.stats.unchangingDraws}');

            ImGui.text('');
            ImGui.text('state changes');
            ImGui.separator();

            ImGui.text('target           ${renderer.stats.targetSwaps}');
            ImGui.text('shader           ${renderer.stats.shaderSwaps}');
            ImGui.text('texture          ${renderer.stats.textureSwaps}');
            ImGui.text('viewport         ${renderer.stats.viewportSwaps}');
            ImGui.text('blend            ${renderer.stats.blendSwaps}');
            ImGui.text('scissor          ${renderer.stats.scissorSwaps}');
        }

        ImGui.end();
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