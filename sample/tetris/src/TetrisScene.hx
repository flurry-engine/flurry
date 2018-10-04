package;

import snow.api.Timer;
import snow.types.Types.ModState;
import snow.Snow;
import snow.api.Emitter;
import snow.types.Types.Key;
import uk.aidanlee.gpu.Renderer;
import uk.aidanlee.scene.Scene;
import uk.aidanlee.resources.ResourceSystem;
import uk.aidanlee.resources.Resource.ImageResource;
import uk.aidanlee.resources.Resource.ShaderResource;
import uk.aidanlee.resources.Resource.TextResource;
import uk.aidanlee.gpu.camera.OrthographicCamera;
import uk.aidanlee.gpu.batcher.Batcher;
import uk.aidanlee.gpu.geometry.Color;
import uk.aidanlee.gpu.geometry.shapes.QuadPackGeometry;
import uk.aidanlee.importers.textureatlas.TextureAtlasParser;
import uk.aidanlee.importers.textureatlas.TextureAtlas;

class TetrisScene extends Scene
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

    public function new(_name : String, _snow : Snow, _parent : Scene, _renderer : Renderer, _resources : ResourceSystem, _events : Emitter<Int>)
    {
        super(_name, _snow, _parent, _renderer, _resources, _events);
    }
    
    /**
     * When the scene is entered setup the board and visual stuff.
     * Also start the timer to cause the active tetromino to automatically drop.
     */
    override function onResumed<T>(_data : T = null)
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
     * Listen for key events for moving and rotating the active tetromino.
     */
    override function onKeyDown(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState)
    {
        switch (_keycode)
        {
            case Key.down : {
                board.move(1, 0);

                timer.stop();
                timer = Timer.delay(0.5, onAutoMove);
            }

            case Key.left : board.move(0, -1);
            case Key.right: board.move(0,  1);
            case Key.key_q: board.ccw();
            case Key.key_e: board.cw();
        }

        updateGrid();
    }

    /**
     * Updates the camera size based on window size.
     * @param _dt Delta time.
     */
    override function onUpdate(_dt : Float)
    {
        camera.viewport.set(0, 0, snow.runtime.window_width(), snow.runtime.window_height());
        camera.update();

        super.onUpdate(_dt);
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
