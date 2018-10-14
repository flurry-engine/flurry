package uk.aidanlee.flurry.api.gpu.imgui;

import cpp.Pointer;
import cpp.RawPointer;
import imgui.ImGui;
import imgui.draw.ImDrawData;
import imgui.util.ImVec2;
import imgui.util.ImVec4;
import snow.Snow;
import snow.api.buffers.Float32Array;
import snow.systems.input.Keycodes;
import uk.aidanlee.flurry.api.gpu.batcher.BufferDrawCommand;
import uk.aidanlee.flurry.api.gpu.camera.OrthographicCamera;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.gpu.backend.IRendererBackend;
import uk.aidanlee.flurry.utils.Hash;

class ImGuiImpl
{
    final app      : Snow;
    final renderer : IRendererBackend;
    final texture  : ImageResource;
    final shader   : ShaderResource;
    final mousePos : Vector;
    final buffer   : Float32Array;
    final camera   : OrthographicCamera;

    public function new(_app : Snow, _renderer : IRendererBackend, _shader : ShaderResource)
    {
        app      = _app;
        renderer = _renderer;
        shader   = _shader;
        camera   = new OrthographicCamera(app.runtime.window_width(), app.runtime.window_height());

        ImGui.createContext();

        var io = ImGui.getIO();
        io.configFlags = ImGuiConfigFlags.NavEnableKeyboard;
        io.keyMap[ImGuiKey.Tab       ] = Scancodes.tab;
        io.keyMap[ImGuiKey.LeftArrow ] = Scancodes.left;
        io.keyMap[ImGuiKey.RightArrow] = Scancodes.right;
        io.keyMap[ImGuiKey.UpArrow   ] = Scancodes.up;
        io.keyMap[ImGuiKey.DownArrow ] = Scancodes.down;
        io.keyMap[ImGuiKey.PageUp    ] = Scancodes.pageup;
        io.keyMap[ImGuiKey.PageDown  ] = Scancodes.pagedown;
        io.keyMap[ImGuiKey.Home      ] = Scancodes.home;
        io.keyMap[ImGuiKey.End       ] = Scancodes.end;
        io.keyMap[ImGuiKey.Delete    ] = Scancodes.delete;
        io.keyMap[ImGuiKey.Backspace ] = Scancodes.backspace;
        io.keyMap[ImGuiKey.Insert    ] = Scancodes.insert;
        io.keyMap[ImGuiKey.Space     ] = Scancodes.space;
        io.keyMap[ImGuiKey.Enter     ] = Scancodes.enter;
        io.keyMap[ImGuiKey.Escape    ] = Scancodes.escape;
        io.keyMap[ImGuiKey.A         ] = Scancodes.key_a;
        io.keyMap[ImGuiKey.C         ] = Scancodes.key_c;
        io.keyMap[ImGuiKey.V         ] = Scancodes.key_v;
        io.keyMap[ImGuiKey.X         ] = Scancodes.key_x;
        io.keyMap[ImGuiKey.Y         ] = Scancodes.key_y;
        io.keyMap[ImGuiKey.Z         ] = Scancodes.key_z;

        var atlas  = Pointer.fromRaw(io.fonts).ref;
        var width  = 0;
        var height = 0;
        var pixels : Array<Int> = null;
        atlas.getTexDataAsRGBA32(pixels, width, height);

        mousePos = new Vector();
        buffer   = new Float32Array(1000000);

        texture = new ImageResource('imgui_texture', width, height, cast pixels);
        renderer.createTexture(texture);

        atlas.texID = Pointer.addressOf(texture).rawCast();

        // Change the imgui style.
        var style = ImGui.getStyle();
        style.windowBorderSize = 0;
        style.frameRounding    = 4;
        style.windowRounding   = 4;
        style.colors[10] = ImVec4.create(0.1, 0.1, 0.1, 1.0);
        style.colors[11] = ImVec4.create(0.1, 0.1, 0.1, 1.0);
        style.colors[12] = ImVec4.create(0.1, 0.1, 0.1, 1.0);
    }

    /**
     * Populates the imgui fields with the latest screen, mouse, keyboard, and gamepad info.
     */
    public function newFrame()
    {
        var io = ImGui.getIO();
        io.displaySize  = ImVec2.create(app.runtime.window_width(), app.runtime.window_height());
        io.mousePos.x   = mousePos.x;
        io.mousePos.y   = mousePos.y;
        io.mouseDown[0] = app.input.mousedown(1);
        io.mouseDown[1] = app.input.mousedown(3);
        io.keyCtrl      = app.input.keydown(Keycodes.lctrl);
        io.keyAlt       = app.input.keydown(Keycodes.lalt);
        io.keyShift     = app.input.keydown(Keycodes.lshift);
        io.keySuper     = app.input.keydown(Keycodes.lmeta);

        io.keysDown[Scancodes.tab      ] = app.input.keypressed(Keycodes.tab);
        io.keysDown[Scancodes.left     ] = app.input.keypressed(Keycodes.left);
        io.keysDown[Scancodes.right    ] = app.input.keypressed(Keycodes.right);
        io.keysDown[Scancodes.up       ] = app.input.keypressed(Keycodes.up);
        io.keysDown[Scancodes.down     ] = app.input.keypressed(Keycodes.down);
        io.keysDown[Scancodes.pageup   ] = app.input.keypressed(Keycodes.pageup);
        io.keysDown[Scancodes.pagedown ] = app.input.keypressed(Keycodes.pagedown);
        io.keysDown[Scancodes.home     ] = app.input.keypressed(Keycodes.home);
        io.keysDown[Scancodes.end      ] = app.input.keypressed(Keycodes.end);
        io.keysDown[Scancodes.enter    ] = app.input.keypressed(Keycodes.enter);
        io.keysDown[Scancodes.backspace] = app.input.keypressed(Keycodes.backspace);
        io.keysDown[Scancodes.escape   ] = app.input.keypressed(Keycodes.escape);
        io.keysDown[Scancodes.delete   ] = app.input.keypressed(Keycodes.delete);
        io.keysDown[Scancodes.key_a    ] = app.input.keypressed(Keycodes.key_a);
        io.keysDown[Scancodes.key_c    ] = app.input.keypressed(Keycodes.key_c);
        io.keysDown[Scancodes.key_v    ] = app.input.keypressed(Keycodes.key_v);
        io.keysDown[Scancodes.key_x    ] = app.input.keypressed(Keycodes.key_x);
        io.keysDown[Scancodes.key_y    ] = app.input.keypressed(Keycodes.key_y);
        io.keysDown[Scancodes.key_z    ] = app.input.keypressed(Keycodes.key_z);

        ImGui.newFrame();
    }

    /**
     * Builds the imgui draw data and renders it into its batcher.
     */
    public function render()
    {
        camera.viewport.set(0, 0, app.runtime.window_width(), app.runtime.window_height());
        camera.size.set_xy(camera.viewport.w, camera.viewport.h);
        camera.update();

        //shader.int.set('ourTexture', 0);

        ImGui.render();
        onRender(ImGui.getDrawData());
    }

    /**
     * Cleans up resources used by the batcher and texture.
     */
    public function dispose()
    {
        renderer.removeTexture(texture);
    }

    /**
     * Set the mouse cursor position.
     * @param _x The x position of the cursor.
     * @param _y The y position of the cursor.
     */
    public function onMouseMove(_x : Float, _y : Float)
    {
        mousePos.x = _x;
        mousePos.y = _y;
    }

    public function onMouseWheel(_v : Float)
    {
        var io = ImGui.getIO();
        io.mouseWheel = _v;
    }

    /**
     * Add text to imgui.
     * @param _text Text to add.
     */
    public function onTextInput(_text : String)
    {
        var io = ImGui.getIO();
        io.addInputCharactersUTF8(_text);
    }

    /**
     * Convert an RGBA integer to a vector.
     * @param _int Integer to convert.
     * @return Vector
     */
    function intToColor(_int : Int) : Vector
    {
        var r = (_int) & 0xFF;
        var g = (_int >> 8) & 0xFF;
        var b = (_int >> 16) & 0xFF;
        var a = (_int >> 24) & 0xFF;

        return new Vector(r / 255, g / 255, b / 255, a / 255);
    }

    /**
     * Creates immediate geometry and places them in the batcher.
     * @param _dataRawPtr Draw data to render.
     */
    function onRender(_dataRawPtr : RawPointer<ImDrawData>) : Void
    {
        var drawData = Pointer.fromRaw(_dataRawPtr).ref;

        var commands  = [];
        var vtxOffset = 0;

        for(i in 0...drawData.cmdListsCount)
        {
            var idxOffset = 0;
            var cmdList   = Pointer.fromRaw(drawData.cmdLists[i]).ref;
            var cmdBuffer = cmdList.cmdBuffer.data;
            var vtxBuffer = cmdList.vtxBuffer.data;
            var idxBuffer = cmdList.idxBuffer.data;
            for (j in 0...cmdList.cmdBuffer.size)
            {
                var cmd   = cmdBuffer[j];
                var start = vtxOffset;
                var clip  = new Rectangle(cmd.clipRect.x, cmd.clipRect.y, cmd.clipRect.z - cmd.clipRect.x, cmd.clipRect.w - cmd.clipRect.y);

                var t  : Pointer<ImageResource> = Pointer.fromRaw(cmd.textureID).reinterpret();
                var it : Int = cast cmd.elemCount / 3;
                for (tri in 0...it)
                {
                    var baseIdx = idxOffset + (tri * 3);
                    var idx1 = idxBuffer[baseIdx + 0];
                    var idx2 = idxBuffer[baseIdx + 1];
                    var idx3 = idxBuffer[baseIdx + 2];
                    var vtx1 = vtxBuffer[idx1];
                    var vtx2 = vtxBuffer[idx2];
                    var vtx3 = vtxBuffer[idx3];

                    buffer[vtxOffset + 0] = vtx1.pos.x;
                    buffer[vtxOffset + 1] = vtx1.pos.y;
                    buffer[vtxOffset + 2] = 0;
                    buffer[vtxOffset + 3] = ((vtx1.col) & 0xFF) / 255;
                    buffer[vtxOffset + 4] = ((vtx1.col >>  8) & 0xFF) / 255;
                    buffer[vtxOffset + 5] = ((vtx1.col >> 16) & 0xFF) / 255;
                    buffer[vtxOffset + 6] = ((vtx1.col >> 24) & 0xFF) / 255;
                    buffer[vtxOffset + 7] = vtx1.uv.x;
                    buffer[vtxOffset + 8] = vtx1.uv.y;
                    vtxOffset += 9;

                    buffer[vtxOffset + 0] = vtx2.pos.x;
                    buffer[vtxOffset + 1] = vtx2.pos.y;
                    buffer[vtxOffset + 2] = 0;
                    buffer[vtxOffset + 3] = ((vtx2.col) & 0xFF) / 255;
                    buffer[vtxOffset + 4] = ((vtx2.col >>  8) & 0xFF) / 255;
                    buffer[vtxOffset + 5] = ((vtx2.col >> 16) & 0xFF) / 255;
                    buffer[vtxOffset + 6] = ((vtx2.col >> 24) & 0xFF) / 255;
                    buffer[vtxOffset + 7] = vtx2.uv.x;
                    buffer[vtxOffset + 8] = vtx2.uv.y;
                    vtxOffset += 9;

                    buffer[vtxOffset + 0] = vtx3.pos.x;
                    buffer[vtxOffset + 1] = vtx3.pos.y;
                    buffer[vtxOffset + 2] = 0;
                    buffer[vtxOffset + 3] = ((vtx3.col) & 0xFF) / 255;
                    buffer[vtxOffset + 4] = ((vtx3.col >>  8) & 0xFF) / 255;
                    buffer[vtxOffset + 5] = ((vtx3.col >> 16) & 0xFF) / 255;
                    buffer[vtxOffset + 6] = ((vtx3.col >> 24) & 0xFF) / 255;
                    buffer[vtxOffset + 7] = vtx3.uv.x;
                    buffer[vtxOffset + 8] = vtx3.uv.y;
                    vtxOffset += 9;
                }

                commands.push(new BufferDrawCommand(buffer, start, vtxOffset, Hash.uniqueHash(), false, camera.projection, camera.viewInverted, cmd.elemCount, camera.viewport, Triangles, null, shader, [ t.ref ], clip, true, SrcAlpha, OneMinusSrcAlpha, One, Zero));

                idxOffset += cmd.elemCount;
            }
        }
        
        // Send commands to renderer backend.
        renderer.uploadBufferCommands(commands);
        renderer.submitCommands(cast commands, true);
    }

    // Callbacks

    static function getClipboard(_data : cpp.RawPointer<cpp.Void>) : cpp.ConstCharStar
    {
        return sdl.SDL.getClipboardText();
    }

    static function setClipboard(_data : cpp.RawPointer<cpp.Void>, _text : cpp.ConstCharStar)
    {
        sdl.SDL.setClipboardText(_text);
    }
}
