package;

import snow.App;
import snow.api.Promise;
import snow.types.Types;
import hxtelemetry.HxTelemetry;
import uk.aidanlee.gpu.Renderer;
import uk.aidanlee.gpu.Shader;
import uk.aidanlee.gpu.Texture;
import uk.aidanlee.gpu.batcher.Batcher;
import uk.aidanlee.gpu.camera.OrthographicCamera;
import uk.aidanlee.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.gpu.imgui.ImGuiImpl;
import uk.aidanlee.maths.Vector;
import uk.aidanlee.resources.ResourceSystem;
import uk.aidanlee.resources.Resource;
import imgui.ImGui;
import imgui.util.ImVec2;

typedef UserConfig = {};

class Main extends App
{
    var hxt : HxTelemetry;

    var renderer : Renderer;
    var resourceSystem : ResourceSystem;
    var imgui    : ImGuiImpl;
    var loaded : Bool;
    var resources : Array<Promise>;

    var shdrHaxe : Shader;
    var txtrHaxe : Texture;
    var txtrLogo : Texture;
    var batcher  : Batcher;
    var camera   : OrthographicCamera;

    var numLogos : Int;
    var sprites  : Array<QuadGeometry>;
    var vectors  : Array<Vector>;

    public function new() {}

    override function config(_config : AppConfig) : AppConfig
    {
        _config.window.title            = 'gpu';
        _config.window.width            = 1600;
        _config.window.height           = 900;
        _config.window.background_sleep = null;

        return _config;
    }

    override function ready()
    {
        loaded = false;

        // Haxe telemetry
        var cfg = new Config();
        cfg.allocations = true;
        cfg.app_name    = 'gpu';

        hxt = new HxTelemetry(cfg);

        // Setup snow timestep.
        // Fixed dt of 16.66
        fixed_timestep = true;
        update_rate    = 1 / 60;

        // Disable auto swapping. We will swap ourselves if the renderer backend requires it.
        app.runtime.auto_swap = false;
        
        // Setup the renderer.
        renderer = new Renderer({

            // The api you choose changes what shaders you need to provide
            // Possible APIs are WEBGL, GL45, DX11, and NULL
            api    : GL45,
            width  : app.runtime.window_width(),
            height : app.runtime.window_height(),
            dpi    : app.runtime.window_device_pixel_ratio(),
            maxUnchangingVertices :  100000,
            maxDynamicVertices    : 1000000,
            backend : {

                // This tells the GL4.5 backend if we can use bindless textures
                bindless : sdl.SDL.GL_ExtensionSupported('GL_ARB_bindless_texture'),

                // The DX11 backend needs to know the games window so it can fetch the HWND for the DXGI swapchain.
                window : app.runtime.window
            }
        });

        resourceSystem = new ResourceSystem();
        resourceSystem.createParcel('default', {
            shaders : [
                {
                    id : 'assets/shaders/textured.json',
                    webgl : { vertex : 'assets/shaders/webgl/textured.vert', fragment : 'assets/shaders/webgl/textured.frag' },
                    gl45  : { vertex : 'assets/shaders/gl45/textured.vert' , fragment : 'assets/shaders/gl45/textured.frag'  },
                    hlsl  : { vertex : 'assets/shaders/hlsl/textured.hlsl' , fragment : 'assets/shaders/hlsl/textured.hlsl'  }
                }
            ],
            images: [
                { id : 'assets/images/haxe.png' },
                { id : 'assets/images/logo.png' }
            ]
        }, onLoaded).load();
    }

    override function update(_dt : Float)
    {
        resourceSystem.update();

        // Pre-draw
        renderer.clear();
        renderer.preRender();

        if (loaded)
        {
            imgui.newFrame();

            // Make all of our haxe logos bounce around the screen.
            for (i in 0...numLogos)
            {
                sprites[i].transformation.position.x += (vectors[i].x * 1000) * _dt;
                sprites[i].transformation.position.y += (vectors[i].y * 1000) * _dt;
                
                if (sprites[i].transformation.position.x > 1600 + sprites[i].transformation.origin.x) vectors[i].x = -vectors[i].x;
                if (sprites[i].transformation.position.x <     0) vectors[i].x = -vectors[i].x;
                if (sprites[i].transformation.position.y >  900 + sprites[i].transformation.origin.y) vectors[i].y = -vectors[i].y;
                if (sprites[i].transformation.position.y <    0)  vectors[i].y = -vectors[i].y;
            }
        }

        // Render and present
        renderer.render();

        if (loaded)
        {
            uiShowRenderStats();
            imgui.render();
        }

        // Post-draw
        // The window_swap is only needed for GL renderers with snow.
        // If using DX11 comment out that line else GL will render over DX.
        renderer.postRender();
        app.runtime.window_swap();

        hxt.advance_frame();
    }

    override function onevent(_event : SystemEvent)
    {
        if (_event.window != null && _event.window.type == WindowEventType.we_resized)
        {
            renderer.resize(_event.window.x, _event.window.y);
        }
    }

    function onLoaded(_resources : Array<Resource>)
    {
        // Create the textured shader
        var shader = resourceSystem.get('assets/shaders/textured.json', ShaderResource);
        shdrHaxe = renderer.backend.createShader(shader.gl45.vertex, shader.gl45.fragment, shader.layout);

        // Create the haxe texture
        var image = resourceSystem.get('assets/images/haxe.png', ImageResource);
        txtrHaxe = renderer.backend.createTexture(image.pixels, image.width, image.height);

        var image = resourceSystem.get('assets/images/logo.png', ImageResource);
        txtrLogo = renderer.backend.createTexture(image.pixels, image.width, image.height);

        camera  = new OrthographicCamera(1600, 900);
        batcher = new Batcher({ shader : shdrHaxe, camera : camera });

        renderer.batchers.push(batcher);

        // Add some sprites.
        sprites  = [];
        vectors  = [];
        numLogos = 10000;
        for (i in 0...numLogos)
        {
            var sprite = new QuadGeometry({ textures : [ txtrHaxe ], batchers : [ batcher ] });
            sprite.transformation.origin  .set_xy(75, 75);
            sprite.transformation.position.set_xy(1600 / 2, 900 / 2);

            sprites.push(sprite);
            vectors.push(random_point_in_unit_circle());
        }

        var logo = new QuadGeometry({ textures : [ txtrLogo ], batchers : [ batcher ], depth : 2, unchanging : true });
        logo.transformation.origin.set_xy(txtrLogo.width / 2, txtrLogo.height / 2);
        logo.transformation.position.set_xy(1600 / 2, 900 / 2);

        imgui = new ImGuiImpl(app, renderer, shdrHaxe);

        loaded = true;
    }

    function random_point_in_unit_circle() : Vector
    {
        var r : Float = Math.sqrt(Math.random());
        var t : Float = (-1 + (2 * Math.random())) * (Math.PI * 2);

        return new Vector(r * Math.cos(t), r * Math.sin(t));
    }

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
}