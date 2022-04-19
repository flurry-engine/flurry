package uk.aidanlee.flurry.modules.imgui;

import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.input.Scancodes;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import VectorMath;
import imgui.ImGui;
import haxe.io.Bytes;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.gpu.GraphicsContext;
import uk.aidanlee.flurry.api.gpu.surfaces.SurfaceID;

@:nullSafety(Off) class DearImGui
{
    final unmanaged : Array<cpp.UInt8>;

    final surfaceID : SurfaceID;

    final display : Display;

    final input : Input;

    public function new(_renderer : Renderer, _display : Display, _input : Input)
    {
        display = _display;
        input   = _input;

        ImGui.createContext();

        final pixels : cpp.Star<cpp.UInt8> = null;
        
        final io        = ImGui.getIO();
        final width     = 0;
        final height    = 0;
        final bpp       = 0;
        final pixelsPtr = cpp.Native.addressOf(pixels);

        io.fonts.getTexDataAsRGBA32(
            pixelsPtr,
            cpp.Native.addressOf(width),
            cpp.Native.addressOf(height),
            cpp.Native.addressOf(bpp));

        unmanaged = cpp.Pointer.fromStar(pixels).toUnmanagedArray(width * height * bpp);

        final stride = bpp * width;
        for (row in 0...height)
        {
            for (col in 0...width)
            {
                final base = col * bpp + row * stride;
                final a    = unmanaged[base + 3];
                final r    = if (a == 0) 1 else unmanaged[base + 0];
                final g    = if (a == 0) 1 else unmanaged[base + 1];
                final b    = if (a == 0) 1 else unmanaged[base + 2];

                unmanaged[base + 0] = Std.int(r * a / 255 + 0.5);
                unmanaged[base + 1] = Std.int(g * a / 255 + 0.5);
                unmanaged[base + 2] = Std.int(b * a / 255 + 0.5);
            }
        }

        surfaceID = _renderer.createSurface({
            width    : width,
            height   : height,
            volatile : false,
            initial  : Bytes.ofData(unmanaged)
        });
        
        io.configFlags  = NavEnableKeyboard;
        io.backendFlags = RendererHasVtxOffset;
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
        io.fonts.texID = untyped __cpp__('(void*)(intptr_t){0}', surfaceID);
    }

    public function newFrame()
    {
        final io = ImGui.getIO();
        io.displaySize  = ImVec2.create(display.width, display.height);
        io.mousePos.x   = display.mouseX;
        io.mousePos.y   = display.mouseY;
        io.mouseDown[0] = input.isMouseDown(1);
        io.mouseDown[1] = input.isMouseDown(3);
        io.keyCtrl      = input.isKeyDown(Keycodes.lctrl);
        io.keyAlt       = input.isKeyDown(Keycodes.lalt);
        io.keyShift     = input.isKeyDown(Keycodes.lshift);
        io.keySuper     = input.isKeyDown(Keycodes.lmeta);

        io.keysDown[Scancodes.tab      ] = input.isKeyDown(Keycodes.tab);
        io.keysDown[Scancodes.left     ] = input.isKeyDown(Keycodes.left);
        io.keysDown[Scancodes.right    ] = input.isKeyDown(Keycodes.right);
        io.keysDown[Scancodes.up       ] = input.isKeyDown(Keycodes.up);
        io.keysDown[Scancodes.down     ] = input.isKeyDown(Keycodes.down);
        io.keysDown[Scancodes.pageup   ] = input.isKeyDown(Keycodes.pageup);
        io.keysDown[Scancodes.pagedown ] = input.isKeyDown(Keycodes.pagedown);
        io.keysDown[Scancodes.home     ] = input.isKeyDown(Keycodes.home);
        io.keysDown[Scancodes.end      ] = input.isKeyDown(Keycodes.end);
        io.keysDown[Scancodes.enter    ] = input.isKeyDown(Keycodes.enter);
        io.keysDown[Scancodes.backspace] = input.isKeyDown(Keycodes.backspace);
        io.keysDown[Scancodes.escape   ] = input.isKeyDown(Keycodes.escape);
        io.keysDown[Scancodes.delete   ] = input.isKeyDown(Keycodes.delete);
        io.keysDown[Scancodes.key_a    ] = input.isKeyDown(Keycodes.key_a);
        io.keysDown[Scancodes.key_c    ] = input.isKeyDown(Keycodes.key_c);
        io.keysDown[Scancodes.key_v    ] = input.isKeyDown(Keycodes.key_v);
        io.keysDown[Scancodes.key_x    ] = input.isKeyDown(Keycodes.key_x);
        io.keysDown[Scancodes.key_y    ] = input.isKeyDown(Keycodes.key_y);
        io.keysDown[Scancodes.key_z    ] = input.isKeyDown(Keycodes.key_z);

        ImGui.newFrame();
    }

    public function draw(_ctx : GraphicsContext)
    {
        ImGui.render();

        final drawData   = ImGui.getDrawData();
        final clipOffset = drawData.displayPos;

        for (i in 0...drawData.cmdListsCount)
        {
            final cmdList   = drawData.cmdLists[i];
            final vtxBuffer = cmdList.vtxBuffer;
            final idxBuffer = cmdList.idxBuffer;

            for (j in 0...cmdList.cmdBuffer.size())
            {
                final cmd : ImDrawCmd = untyped __cpp__('{0}->CmdBuffer[{1}]', cmdList, j);
                final sid = untyped __cpp__('(intptr_t){0}', cmd.textureId);

                final x1 = Std.int(cmd.clipRect.x - clipOffset.x);
                final y1 = Std.int(cmd.clipRect.y - clipOffset.y);
                final x2 = Std.int(cmd.clipRect.z - clipOffset.x);
                final y2 = Std.int(cmd.clipRect.w - clipOffset.y);

                _ctx.useScissorRegion(x1, y1, x2 - x1, y2 - y1);
                _ctx.useSurface(0, sid, SamplerState.nearest);
                _ctx.prepare();

                for (k in 0...cmd.elemCount)
                {
                    final idx = idxBuffer.data[cmd.idxOffset + k];

                    final x : Float = untyped __cpp__('{0}.Data[{1}].pos.x', vtxBuffer, idx);
                    final y : Float = untyped __cpp__('{0}.Data[{1}].pos.y', vtxBuffer, idx);

                    final r : Float = untyped __cpp__('(({0}.Data[{1}].col) & 0xFF) / 255.0', vtxBuffer, idx);
                    final g : Float = untyped __cpp__('(({0}.Data[{1}].col >>  8) & 0xFF) / 255.0', vtxBuffer, idx);
                    final b : Float = untyped __cpp__('(({0}.Data[{1}].col >> 16) & 0xFF) / 255.0', vtxBuffer, idx);
                    final a : Float = untyped __cpp__('(({0}.Data[{1}].col >> 24) & 0xFF) / 255.0', vtxBuffer, idx);

                    final u : Float = untyped __cpp__('{0}.Data[{1}].uv.x', vtxBuffer, idx);
                    final v : Float = untyped __cpp__('{0}.Data[{1}].uv.y', vtxBuffer, idx);

                    final pos = vec3(x, y, 0);
                    final col = vec4(r * a, g * a, b * a, a);
                    final tex = vec2(u, v);

                    _ctx.vtxOutput.write(pos);
                    _ctx.vtxOutput.write(col);
                    _ctx.vtxOutput.write(tex);

                    _ctx.idxOutput.write(k);
                }
            }
        }
    }
}