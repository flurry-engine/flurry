package uk.aidanlee.flurry.api.display;

import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.display.DisplayEvents;

using rx.Observable;

class Display
{
    public var mouseX (default, null) : Int;

    public var mouseY (default, null) : Int;

    public var width (default, null) : Int;

    public var height (default, null) : Int;

    public var fullscreen (default, null) : Bool;

    public var vsync (default, null) : Bool;

    final displayEvents : DisplayEvents;
    
    final inputEvents : InputEvents;

    public function new(_displayEvents : DisplayEvents, _inputEvents : InputEvents, _config : FlurryConfig)
    {
        displayEvents = _displayEvents;
        inputEvents   = _inputEvents;
        width         = _config.window.width;
        height        = _config.window.height;
        fullscreen    = _config.window.fullscreen;
        vsync         = _config.window.vsync;
        mouseX        = 0;
        mouseY        = 0;

        displayEvents.sizeChanged.subscribeFunction(onResizeEvent);
        inputEvents.mouseMove.subscribeFunction(onMouseMoveEvent);
    }

    public function change(_width : Int, _height : Int, _fullscreen : Bool, _vsync : Bool)
    {
        displayEvents.changeRequested.onNext(new DisplayEventChangeRequest(_width, _height, _fullscreen, _vsync));

        fullscreen = _fullscreen;
        vsync      = _vsync;        
    }

    function onResizeEvent(_data : DisplayEventData)
    {
        width  = _data.width;
        height = _data.height;
    }

    function onMouseMoveEvent(_data : InputEventMouseMove)
    {
        mouseX = _data.x;
        mouseY = _data.y;
    }
}
