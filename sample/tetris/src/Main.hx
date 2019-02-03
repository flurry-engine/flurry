
import snow.api.Timer;
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.TextResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlasParser;
import uk.aidanlee.flurry.api.importers.textureatlas.TextureAtlas;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadPackGeometry;
import uk.aidanlee.flurry.api.gpu.geometry.Color;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.camera.OrthographicCamera;

typedef UserConfig = {};

class Main extends Flurry
{
    /**
     * 2D camera to view our tetris board.
     */
    var camera : OrthographicCamera;

    /**
     * Batcher store the quad geometry in.
     */
    var batcher : Batcher;

    /**
     * The tetris game board.
     */
    var board : Board;

    /**
     * Atlas for the tetris shapes.
     */
    var atlas : TextureAtlas;

    /**
     * Quad pack geometry to display the grid.
     */
    var landedQuads : QuadPackGeometry;

    /**
     * All the IDs of the quads in the quad pack geometry.
     */
    var quadIDs : Array<Array<Int>>;

    /**
     * Repeating timer to cause the active tetromino to fall.
     */
    var timer : Timer;

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = GLES;

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
        board   = new Board();
        camera  = new OrthographicCamera(400, 800);
        batcher = renderer.createBatcher({ camera : camera, shader : resources.get('assets/shaders/textured.json', ShaderResource) });
        atlas   = TextureAtlasParser.parse(resources.get('assets/images/shapes.atlas', TextResource).content);

        landedQuads = new QuadPackGeometry({batchers : [ batcher ], textures : [ resources.get('assets/images/shapes.png', ImageResource) ] });
        quadIDs     = [ for (row in 0...board.gridRows) [ for (col in 0...board.gridCols) landedQuads.add_xywh(atlas.findRegionID('block', board.landed[row][col]), col * 40, row * 40, 40, 40, new Color()) ] ];

        updateGrid();

        timer = Timer.delay(0.5, onAutoMove);
    }

    /**
     * Simulate all of the engines components.
     * @param _dt 
     */
    override function onUpdate(_dt : Float)
    {
        camera.viewport.set(0, 0, 1600, 900);
        camera.update();

        if (input.isKeyDown(Keycodes.down))
        {
            board.move(1, 0);

            timer.stop();
            timer = Timer.delay(0.5, onAutoMove);
        }
        if (input.wasKeyPressed(Keycodes.left))
        {
            board.move(0, -1);
        }
        if (input.wasKeyPressed(Keycodes.right))
        {
            board.move(0,  1);
        }
        if (input.wasKeyPressed(Keycodes.key_q))
        {
            board.ccw();
        }
        if (input.wasKeyPressed(Keycodes.key_e))
        {
            board.cw();
        }

        updateGrid();
    }

        /**
     * Called every half a second and will move the active tetromino down a row.
     */
    function onAutoMove()
    {
        board.move(1, 0);
        updateGrid();

        timer = Timer.delay(0.5, onAutoMove);
    }

    /**
     * Updates the grid visuals based on the landed tetrominoes and active tetromino.
     */
    function updateGrid()
    {
        // Update the UV for the grid.
        for (row in 0...board.gridRows)
        {
            for (col in 0...board.gridCols)
            {
                landedQuads.quadTile(quadIDs[row][col], atlas.findRegionID('block', board.landed[row][col]));
            }
        }

        // Set the quads for the active shape
        for (row in 0...board.active.shape.length)
        {
            for (col in 0...board.active.shape[row].length)
            {
                if (board.active.shape[row][col] != 0)
                {
                    landedQuads.quadTile(quadIDs[board.active.row + row][board.active.col + col], atlas.findRegionID('block', board.active.shape[row][col]));
                }
            }
        }
    }
}