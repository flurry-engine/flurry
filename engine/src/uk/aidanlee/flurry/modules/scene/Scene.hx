package uk.aidanlee.flurry.modules.scene;

import snow.Snow;
import snow.api.Emitter;
import snow.types.Types.GamepadDeviceEventType;
import snow.types.Types.TextEventType;
import snow.types.Types.ModState;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.gpu.Renderer;

class Scene
{
    /**
     * Unique name of this scene.
     */
    public final name : String;

    /**
     * If this scene has been created and not destroyed.
     */
    public var created (default, null) : Bool;

    /**
     * If this scene is currently paused.
     */
    public var paused (default, null) : Bool;

    /**
     * If this scene should have resume() called when its created.
     */
    public var resumeOnCreation : Bool;

    /**
     * Access to the underlying snow app.
     * Will eventually be removed as things will be provided by the engine instead of snow.
     * This way the engine does not become dependent on snow.
     */
    final snow : Snow;

    /**
     * Parent scene. If null then this is the root scene.
     */
    final parent : Scene;

    /**
     * All child scenes.
     */
    final children : Array<Scene>;

    /**
     * Access to the engine renderer.
     */
    final renderer : Renderer;

    /**
     * Access to the engine resources.
     */
    final resources : ResourceSystem;

    /**
     * Access to the engine events bus.
     */
    final events : Emitter<Int>;

    /**
     * The currently active child. Null if no child is active.
     */
    var activeChild : Scene;

    public function new(_name : String, _snow : Snow, _parent : Scene, _renderer : Renderer, _resources : ResourceSystem, _events : Emitter<Int>)
    {
        name             = _name;
        paused           = true;
        created          = false;
        resumeOnCreation = false;

        children  = [];
        snow      = _snow;
        parent    = _parent;
        renderer  = _renderer;
        resources = _resources;
        events    = _events;
    }

    /**
     * Issue the create event to a scene and all its children.
     * @param _data The data to be sent to each scene.
     */
    public final function create<T>(_data : T = null, _resume : Null<Bool> = null)
    {
        if (created) return;

        if (_resume == null)
        {
            _resume = resumeOnCreation;
        }

        created = true;
        onCreated(_data);

        if (_resume)
        {
            paused = false;
            onResumed(_data);
        }

        for (child in children)
        {
            child.create(_data, _resume);
        }
    }

    /**
     * Remove a scene and all its children.
     * @param _data The data to be sent to each scene.
     */
    public final function remove<T>(_data : T = null)
    {
        if (!created) return;

        if (!paused)
        {
            paused = true;
            onPaused(_data);
        }

        onRemoved(_data);
        created = false;

        for (child in children)
        {
            child.remove(_data);
        }
    }

    /**
     * Pause a scene and all its children
     * @param _data Data to send to all scenes.
     */
    public final function pause<T>(_data : T = null)
    {
        if (!created) return;

        paused = true;
        onPaused(_data);

        for (child in children)
        {
            child.pause(_data);
        }
    }

    /**
     * Resume a scene and all its children.
     * @param _data Data to send to all scenes.
     */
    public final function resume<T>(_data : T = null)
    {
        if (!created) return;

        paused = false;
        onResumed(_data);

        for (child in children)
        {
            child.resume(_data);
        }
    }

    /**
     * Send an update to a scene and all its children.
     * @param _dt Delta time.
     */
    public final function update(_dt : Float)
    {
        if (!created || paused) return;

        onUpdate(_dt);

        for (child in children)
        {
            child.update(_dt);
        }
    }

    /**
     * Recursively search the tree for a scene with a specific name.
     * @param _name       The name of the scene to find.
     * @param _depthFirst If the scene tree should be searched depth first (defaults false).
     * @param _type       If the retured scene should be casted to a specific type (defaults Scene).
     * @return T : Scene
     */
    public function getChild<T : Scene>(_type : Class<T>, _name : String, _depthFirst : Bool = false) : T
    {
        if (name == _name)
        {
            return cast this;
        }

        if (_depthFirst)
        {
            // DFS, after checking a child we immediately start searching its children first instead of our other children.
            for (child in children)
            {
                if (child.name == _name)
                {
                    return cast child;
                }
                else
                {
                    var found = child.getChild(_type, _name, _depthFirst);
                    if (found != null)
                    {
                        return found;
                    }
                }
            }
        }
        else
        {
            for (child in children)
            {
                if (child.name == name)
                {
                    return cast child;
                }
            }

            for (child in children)
            {
                var found = child.getChild(_type, _name, _depthFirst);
                if (found != null)
                {
                    return found;
                }
            }
        }

        return null;
    }

    /**
     * Create a child of this scene. The scenes create event is automatically called.
     * @param _type       The scene type to add.
     * @param _name       The name of the scene.
     * @param _arguments  The custom user defined arguments required by the scene.
     * @param _autoCreate If the added child should have create() called immediately
     * @return T
     */
    @:generic public function addChild<T : Scene>(_type : Class<T>, _name : String, _arguments : Array<Dynamic> = null, _autoCreate = false) : T
    {
        if (_arguments == null)
        {
            _arguments = [];
        }

        var requiredArguments : Array<Dynamic> = [ _name, snow, this, renderer, resources, null ];
        var child = Type.createInstance(_type, requiredArguments.concat(_arguments));

        children.push(child);

        if (_autoCreate)
        {
            child.create();
        }

        return child;
    }

    /**
     * Remove a child from a scene. Remove is automatically called.
     * @param _child Child to remove.
     */
    public function removeChild(_child : Scene)
    {
        _child.remove();
        children.remove(_child);
    }

    @:noCompletion public final function mouseUp(_x : Int, _y : Int, _button : Int)
    {
        if (!created || paused) return;

        onMouseUp(_x, _y, _button);

        for (child in children)
        {
            child.mouseUp(_x, _y, _button);
        }
    }
    @:noCompletion public final function mouseDown(_x : Int, _y : Int, _button : Int)
    {
        if (!created || paused) return;

        onMouseDown(_x, _y, _button);

        for (child in children)
        {
            child.mouseDown(_x, _y, _button);
        }
    }
    @:noCompletion public final function mouseMove(_x : Int, _y : Int, _xRel : Int, _yRel : Int)
    {
        if (!created || paused) return;

        onMouseMove(_x, _y, _xRel, _yRel);

        for (child in children)
        {
            child.mouseMove(_x, _y, _xRel, _yRel);
        }
    }
    @:noCompletion public final function mouseWheel(_x : Float, _y : Float)
    {
        if (!created || paused) return;

        onMouseWheel(_x, _y);

        for (child in children)
        {
            child.mouseWheel(_x, _y);
        }
    }

    @:noCompletion public final function keyUp(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState)
    {
        if (!created || paused) return;

        onKeyUp(_keycode, _scancode, _repeat, _mod);

        for (child in children)
        {
            child.keyUp(_keycode, _scancode, _repeat, _mod);
        }
    }
    @:noCompletion public final function keyDown(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState)
    {
        if (!created || paused) return;

        onKeyDown(_keycode, _scancode, _repeat, _mod);

        for (child in children)
        {
            child.keyDown(_keycode, _scancode, _repeat, _mod);
        }
    }
    @:noCompletion public final function textInput(_text : String, _start : Int, _length : Int, _type : TextEventType)
    {
        if (!created || paused) return;

        onTextInput(_text, _start, _length, _type);

        for (child in children)
        {
            child.textInput(_text, _start, _length, _type);
        }
    }

    @:noCompletion public final function gamepadDown(_gamepad : Int, _button : Int, _value : Float)
    {
        if (!created || paused) return;

        onGamepadDown(_gamepad, _button, _value);

        for (child in children)
        {
            child.gamepadDown(_gamepad, _button, _value);
        }
    }
    @:noCompletion public final function gamepadUp(_gamepad : Int, _button : Int, _value : Float)
    {
        if (!created || paused) return;

        onGamepadUp(_gamepad, _button, _value);

        for (child in children)
        {
            child.gamepadUp(_gamepad, _button, _value);
        }
    }
    @:noCompletion public final function gamepadAxis(_gamepad : Int, _axis : Int, _value : Float)
    {
        if (!created || paused) return;

        onGamepadAxis(_gamepad, _axis, _value);

        for (child in children)
        {
            child.gamepadAxis(_gamepad, _axis, _value);
        }
    }
    @:noCompletion public final function gamepadDevice(_gamepad : Int, _id : String, _type : GamepadDeviceEventType)
    {
        if (!created || paused) return;

        onGamepadDevice(_gamepad, _id, _type);

        for (child in children)
        {
            child.gamepadDevice(_gamepad, _id, _type);
        }
    }

    // #region Event functions overwrittable by the user.

    function onCreated<T>(_data : T = null) { }
    function onRemoved<T>(_data : T = null) { }
    function onPaused<T>(_data : T = null) { }
    function onResumed<T>(_data : T = null) { }
    function onUpdate(_dt : Float) { }

    function onMouseUp(_x : Int, _y : Int, _button : Int) {}
    function onMouseDown(_x : Int, _y : Int, _button : Int) {}
    function onMouseMove(_x : Int, _y : Int, _xRel : Int, _yRel : Int)  {}
    function onMouseWheel(_x : Float, _y : Float) {}

    function onKeyUp(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState) {}
    function onKeyDown(_keycode : Int, _scancode : Int, _repeat : Bool, _mod : ModState) {}
    function onTextInput(_text : String, _start : Int, _length : Int, _type : TextEventType) {}

    function onGamepadDown(_gamepad : Int, _button : Int, _value : Float) {}
    function onGamepadUp(_gamepad : Int, _button : Int, _value : Float) {}
    function onGamepadAxis(_gamepad : Int, _axis : Int, _value : Float) {}
    function onGamepadDevice(_gamepad : Int, _id : String, _type : GamepadDeviceEventType) {}

    // #endregion
}
