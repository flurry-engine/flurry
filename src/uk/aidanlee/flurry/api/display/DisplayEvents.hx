package uk.aidanlee.flurry.api.display;

import signals.Signal1;

class DisplayEvents
{
    public final unknown : Signal1<DisplayEventData>;
    
    public final shown : Signal1<DisplayEventData>;

    public final hidden : Signal1<DisplayEventData>;

    public final exposed : Signal1<DisplayEventData>;

    public final moved : Signal1<DisplayEventData>;

    public final minimised : Signal1<DisplayEventData>;

    public final maximised : Signal1<DisplayEventData>;

    public final restored : Signal1<DisplayEventData>;

    public final enter : Signal1<DisplayEventData>;

    public final leave : Signal1<DisplayEventData>;

    public final focusGained : Signal1<DisplayEventData>;

    public final focusLost : Signal1<DisplayEventData>;

    public final close : Signal1<DisplayEventData>;

    public final resized : Signal1<DisplayEventData>;

    public final sizeChanged : Signal1<DisplayEventData>;

    public final changeRequested : Signal1<DisplayEventChangeRequest>;

    public function new()
    {
        unknown         = new Signal1<DisplayEventData>();
        shown           = new Signal1<DisplayEventData>();
        hidden          = new Signal1<DisplayEventData>();
        exposed         = new Signal1<DisplayEventData>();
        moved           = new Signal1<DisplayEventData>();
        minimised       = new Signal1<DisplayEventData>();
        maximised       = new Signal1<DisplayEventData>();
        restored        = new Signal1<DisplayEventData>();
        enter           = new Signal1<DisplayEventData>();
        leave           = new Signal1<DisplayEventData>();
        focusGained     = new Signal1<DisplayEventData>();
        focusLost       = new Signal1<DisplayEventData>();
        close           = new Signal1<DisplayEventData>();
        resized         = new Signal1<DisplayEventData>();
        sizeChanged     = new Signal1<DisplayEventData>();
        changeRequested = new Signal1<DisplayEventChangeRequest>();
    }
}

class DisplayEventData
{
    public final width : Int;

    public final height : Int;

    public function new(_width : Int, _height : Int)
    {
        width  = _width;
        height = _height;
    }
}

class DisplayEventChangeRequest
{
    public final width : Int;

    public final height : Int;

    public final fullscreen : Bool;

    public final vsync : Bool;

    public function new(_width : Int, _height : Int, _fullscreen : Bool, _vsync : Bool)
    {
        width      = _width;
        height     = _height;
        fullscreen = _fullscreen;
        vsync      = _vsync;
    }
}
