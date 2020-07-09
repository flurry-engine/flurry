package uk.aidanlee.flurry.modules.imgui;

import cpp.Star;
import cpp.Stdlib;
import cpp.Pointer;
import cpp.ConstPointer;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.batcher.DrawCommand;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry;
import uk.aidanlee.flurry.api.gpu.geometry.IndexBlob;
import uk.aidanlee.flurry.api.gpu.geometry.VertexBlob;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.DepthState;
import uk.aidanlee.flurry.api.gpu.state.StencilState;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.input.Keycodes;
import uk.aidanlee.flurry.api.input.Scancodes;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventTextInput;
import uk.aidanlee.flurry.api.buffers.UInt16BufferData;
import uk.aidanlee.flurry.api.buffers.Float32BufferData;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import rx.disposables.ISubscription;
import imgui.ImGui;

using cpp.Native;
using cpp.NativeArray;
using rx.Observable;

class ImGuiImpl
{
    final events    : FlurryEvents;
    final display   : Display;
    final resources : ResourceSystem;
    final input     : Input;
    final renderer  : Renderer;
    final shader    : ShaderResource;
    
    final texture  : ImageResource;
    final frame    : ImageFrameResource;
    final camera   : Camera2D;
    final depth    : DepthState;
    final stencil  : StencilState;
    final blend    : BlendState;

    final onTextSubscription : ISubscription;

    public function new(_events : FlurryEvents, _display : Display, _resources : ResourceSystem, _input : Input, _renderer : Renderer, _shader : ShaderResource)
    {
        events    = _events;
        display   = _display;
        resources = _resources;
        input     = _input;
        renderer  = _renderer;
        shader    = _shader;
        camera    = _renderer.createCamera2D(display.width, display.height);
        depth     = {
            depthTesting  : false,
            depthMasking  : false,
            depthFunction : Always
        };
        stencil = {
            stencilTesting : false,

            stencilFrontMask          : 0xff,
            stencilFrontFunction      : Always,
            stencilFrontTestFail      : Keep,
            stencilFrontDepthTestFail : Keep,
            stencilFrontDepthTestPass : Keep,
            
            stencilBackMask          : 0xff,
            stencilBackFunction      : Always,
            stencilBackTestFail      : Keep,
            stencilBackDepthTestFail : Keep,
            stencilBackDepthTestPass : Keep
        }
        blend = new BlendState();

        ImGui.createContext();

        final io = ImGui.getIO();
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
        io.setClipboardTextFn = cpp.Callable.fromStaticFunction(setClipboard);
        io.getClipboardTextFn = cpp.Callable.fromStaticFunction(getClipboard);

        final width  = 0;
        final height = 0;
        final bpp    = 0;
        final pixels : cpp.Star<cpp.UInt8> = null;
        final pixelPtr : cpp.Star<cpp.Star<cpp.UInt8>> = pixels.addressOf();

        io.fonts.getTexDataAsRGBA32(pixelPtr, width, height, bpp);

        texture = new ImageResource(
            'imgui_texture',
            width,
            height,
            BGRAUNorm,
            Pointer.fromStar(pixels).toUnmanagedArray(width * height * bpp));
        frame = new ImageFrameResource(
            'imgui_frame',
            'imgui_texture',
            0, 0, texture.width, texture.height,
            0, 0, 1, 1);
        
        io.fonts.texID = cast Pointer.addressOf(frame).ptr;

        resources.addResource(texture);
        resources.addResource(frame);

        onTextSubscription = events.input.textInput.subscribeFunction(onTextInput);
    }

    /**
     * Populates the imgui fields with the latest screen, mouse, keyboard, and gamepad info.
     */
    public function newFrame()
    {
        var io = ImGui.getIO();
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

    /**
     * Builds the imgui draw data and renders it into its batcher.
     */
    public function render()
    {
        camera.viewport = Viewport(0, 0, display.width, display.height);
        camera.size.set(display.width, display.height);
        camera.update(1000 / 60);

        ImGui.render();
        onRender(ImGui.getDrawData());
    }

    /**
     * Cleans up resources used by the batcher and texture.
     */
    public function dispose()
    {
        onTextSubscription.unsubscribe();

        resources.removeResource(frame);
        resources.removeResource(texture);
    }

    /**
     * Add text to imgui.
     * @param _text Text to add.
     */
    function onTextInput(_text : InputEventTextInput)
    {
        var io = ImGui.getIO();
        io.addInputCharactersUTF8(_text.text);
    }

    /**
     * Creates immediate geometry and places them in the batcher.
     * @param _drawData Draw data to render.
     */
    function onRender(_drawData : Star<ImDrawData>) : Void
    {
        for (i in 0..._drawData.cmdListsCount)
        {
            final cmdList = _drawData.cmdLists[i];
            final cmdBuffer = cmdList.cmdBuffer.data;
            final vtxBuffer = cmdList.vtxBuffer.data;
            final idxBuffer = cmdList.idxBuffer.data;

            final vtxBytes = new Float32BufferData(cmdList.vtxBuffer.size() * 9);
            final idxBytes = new UInt16BufferData(cmdList.idxBuffer.size());

            var idx = 0;
            for (j in 0...cmdList.vtxBuffer.size())
            {
                vtxBytes[idx++] = vtxBuffer[j].pos.x;
                vtxBytes[idx++] = vtxBuffer[j].pos.y;
                vtxBytes[idx++] = 0;
                vtxBytes[idx++] = ((vtxBuffer[j].col) & 0xFF) / 255;
                vtxBytes[idx++] = ((vtxBuffer[j].col >>  8) & 0xFF) / 255;
                vtxBytes[idx++] = ((vtxBuffer[j].col >> 16) & 0xFF) / 255;
                vtxBytes[idx++] = ((vtxBuffer[j].col >> 24) & 0xFF) / 255;
                vtxBytes[idx++] = vtxBuffer[j].uv.x;
                vtxBytes[idx++] = vtxBuffer[j].uv.y;
            }

            Stdlib.memcpy(
                idxBytes.bytes.getData().address(0),
                ConstPointer.fromRaw(idxBuffer), cmdList.idxBuffer.size() * 2);

            for (j in 0...cmdList.cmdBuffer.size())
            {
                final draw = cmdBuffer[j];
                final t : Pointer<ImageFrameResource> = Pointer.fromRaw(draw.textureId).reinterpret();

                renderer.backend.queue(
                    new DrawCommand(
                        [ new Geometry({
                            data : Indexed(
                                new VertexBlob(vtxBytes),
                                new IndexBlob(idxBytes.sub(draw.idxOffset, draw.elemCount)))
                            }) ],
                        camera,
                        Triangles,
                        Clip(
                            Std.int(draw.clipRect.x),
                            Std.int(draw.clipRect.y),
                            Std.int(draw.clipRect.z - draw.clipRect.x),
                            Std.int(draw.clipRect.w - draw.clipRect.y)),
                        Backbuffer,
                        shader,
                        [],
                        [ t.value ],
                        [],
                        depth,
                        stencil,
                        blend));
            }
        }
    }

    // Callbacks

    static function getClipboard(_data : cpp.Star<cpp.Void>) : cpp.ConstCharStar
    {
        return sdl.SDL.getClipboardText();
    }

    @:void static function setClipboard(_data : cpp.Star<cpp.Void>, _text : cpp.ConstCharStar)
    {
        sdl.SDL.setClipboardText(_text);
    }
}
