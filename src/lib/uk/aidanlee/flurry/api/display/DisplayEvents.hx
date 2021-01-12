package uk.aidanlee.flurry.api.display;

import hxrx.subjects.PublishSubject;

class DisplayEvents
{
    public final unknown : PublishSubject<DisplayEventData>;
    
    public final shown : PublishSubject<DisplayEventData>;

    public final hidden : PublishSubject<DisplayEventData>;

    public final exposed : PublishSubject<DisplayEventData>;

    public final moved : PublishSubject<DisplayEventData>;

    public final minimised : PublishSubject<DisplayEventData>;

    public final maximised : PublishSubject<DisplayEventData>;

    public final restored : PublishSubject<DisplayEventData>;

    public final enter : PublishSubject<DisplayEventData>;

    public final leave : PublishSubject<DisplayEventData>;

    public final focusGained : PublishSubject<DisplayEventData>;

    public final focusLost : PublishSubject<DisplayEventData>;

    public final close : PublishSubject<DisplayEventData>;

    public final resized : PublishSubject<DisplayEventData>;

    public final sizeChanged : PublishSubject<DisplayEventData>;

    public final changeRequested : PublishSubject<DisplayEventChangeRequest>;

    public function new()
    {
        unknown         = new PublishSubject();
        shown           = new PublishSubject();
        hidden          = new PublishSubject();
        exposed         = new PublishSubject();
        moved           = new PublishSubject();
        minimised       = new PublishSubject();
        maximised       = new PublishSubject();
        restored        = new PublishSubject();
        enter           = new PublishSubject();
        leave           = new PublishSubject();
        focusGained     = new PublishSubject();
        focusLost       = new PublishSubject();
        close           = new PublishSubject();
        resized         = new PublishSubject();
        sizeChanged     = new PublishSubject();
        changeRequested = new PublishSubject();
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
