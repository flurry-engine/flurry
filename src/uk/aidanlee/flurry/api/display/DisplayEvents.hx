package uk.aidanlee.flurry.api.display;

import rx.Subject;

class DisplayEvents
{
    public final unknown : Subject<DisplayEventData>;
    
    public final shown : Subject<DisplayEventData>;

    public final hidden : Subject<DisplayEventData>;

    public final exposed : Subject<DisplayEventData>;

    public final moved : Subject<DisplayEventData>;

    public final minimised : Subject<DisplayEventData>;

    public final maximised : Subject<DisplayEventData>;

    public final restored : Subject<DisplayEventData>;

    public final enter : Subject<DisplayEventData>;

    public final leave : Subject<DisplayEventData>;

    public final focusGained : Subject<DisplayEventData>;

    public final focusLost : Subject<DisplayEventData>;

    public final close : Subject<DisplayEventData>;

    public final resized : Subject<DisplayEventData>;

    public final sizeChanged : Subject<DisplayEventData>;

    public final changeRequested : Subject<DisplayEventChangeRequest>;

    public function new()
    {
        unknown         = new Subject();
        shown           = new Subject();
        hidden          = new Subject();
        exposed         = new Subject();
        moved           = new Subject();
        minimised       = new Subject();
        maximised       = new Subject();
        restored        = new Subject();
        enter           = new Subject();
        leave           = new Subject();
        focusGained     = new Subject();
        focusLost       = new Subject();
        close           = new Subject();
        resized         = new Subject();
        sizeChanged     = new Subject();
        changeRequested = new Subject();
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
