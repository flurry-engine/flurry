package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import rx.Subject;
import rx.observables.IObservable;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.GeometryUniforms;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.GeometryShader;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteFrameResource;
import haxe.Exception;
import haxe.ds.ReadOnlyArray;

using Safety;

typedef SpriteOptions = {
    var sprite : SpriteResource;
    var animation : String;
    var ?sampler : SamplerState;
    var ?shader : GeometryShader;
    var ?uniforms : GeometryUniforms;
    var ?depth : Float;
    var ?clip : ClipState;
    var ?blend : BlendState;
    var ?batchers : Array<Batcher>;
    var ?x : Float;
    var ?y : Float;
    var ?xScale : Float;
    var ?yScale : Float;
    var ?xOrigin : Int;
    var ?yOrigin : Int;
    var ?speed : Float;
    var ?angle : Float;
    var ?playing : Bool;
}

class SpriteGeometry extends QuadGeometry
{
    /**
     * Read only unit vector for creating a rotation matrix when the angle changes.
     */
    static final rotationUnit = new Vector3(0, 0, 1);

    /**
     * The speed multiplier applied to the animations.
     */
    public var speed : Float;

    /**
     * Current angle in degrees of this sprite.
     */
    public var angle (default, set) : Float;

    inline function set_angle(_v)
    {
        rotation.setFromAxisAngle(rotationUnit, Maths.toRadians(_v));

        return angle = _v;
    }

    /**
     * If the animation is currently playing or paused.
     */
    public var playing : Bool;

    /**
     * The current width of the sprite.
     * Current frame width multipled by the x scale.
     */
    public var width (get, null) : Float;

    inline function get_width() return currentAnimation[index].width * scale.x;

    /**
     * The current height of the sprite.
     * Current frame height multiplied by the y scale.
     */
    public var height (get, null) : Float;

    inline function get_height() return currentAnimation[index].height * scale.y;

    /**
     * Ticks the name of the animation when it changes.
     */
    public final onAnimation : IObservable<String>;

    /**
     * Ticks the index of the current animation frame when it changes.
     */
    public final onFrame : IObservable<Int>;

    /**
     * All of the animation frames keyed by their name.
     */
    final animations : Map<String, Array<SpriteFrameResource>>;

    /**
     * The current animation set being played.
     */
    var currentAnimation : ReadOnlyArray<SpriteFrameResource>;

    /**
     * Index into the current animation for the current frame.
     */
    var index : Int;

    /**
     * Number of miliseconds the current frame has been displayed for.
     * This value is incremented by calling `update` when `playing` is true.
     */
    var time : Float;

    public function new(_options : SpriteOptions)
    {
        super({
            texture  : _options.sprite,
            sampler  : _options.sampler,
            shader   : _options.shader,
            uniforms : _options.uniforms,
            depth    : _options.depth,
            clip     : _options.clip,
            blend    : _options.blend,
            batchers : _options.batchers,
            x        : _options.x,
            y        : _options.y
        });

        scale.x     = _options.xScale.or(1);
        scale.y     = _options.yScale.or(1);
        origin.x    = _options.xOrigin.or(0);
        origin.y    = _options.yOrigin.or(0);
        animations  = _options.sprite.animations;
        speed       = _options.speed.or(1);
        angle       = _options.angle.or(0);
        index       = 0;
        time        = 0;
        onAnimation = new Subject<String>();
        onFrame     = new Subject<Int>();

        play(_options.animation);
    }

    /**
     * Start playing the animation with the provided name.
     * @param _name Name of the animation to play.
     * @throws `AnimationNotFoundException` if the provided animation name does not exist.
     */
    public function play(_name : String)
    {
        if (animations.exists(_name))
        {
            currentAnimation = animations[_name];
            playing          = true;
            index            = 0;
            time             = 0;

            (cast onAnimation : Subject<String>).onNext(_name);

            applyFrame(currentAnimation, index);
        }
        else
        {
            throw new AnimationNotFoundException(_name);
        }
    }

    /**
     * Reset the current animation and begin playing.
     */
    public function restart()
    {
        playing = true;
        index   = 0;
        time    = 0;

        frame(index);
    }

    /**
     * Changes the current frame of the animation set.
     * Does not change the playing state.
     * @param _index Index of the frame.
     * @throws `OutOfRangeException` if the index is greater than the number of frames.
     */
    public function frame(_index : Int)
    {
        if (_index < 0 || _index >= currentAnimation.length)
        {
            throw new OutOfRangeException(_index, currentAnimation.length);
        }

        index = _index;
        time  = 0;
        applyFrame(currentAnimation, index);
    }

    /**
     * Update the sprite. If the sprite is playing the provided miliseconds are added to the internal time tracker.
     * Once this time is equal or exceeds the current frames duration the next frame is displayed and the timer reset.
     * @param _time Time in miliseconds to add.
     */
    public function update(_time : Float)
    {
        if (!playing)
        {
            return;
        }
        
        time += _time * speed;

        if (time >= currentAnimation[index].duration)
        {
            index = (index + 1) % currentAnimation.length;
            time  = 0;

            applyFrame(currentAnimation, index);
        }
    }

    /**
     * Update the visuals of this geometry to match the provided sprite frame.
     * UV coordinates and geometry size is updated.
     * @param _frames All of the frames in the current animation.
     * @param _index Index of the current frame in the animation.
     */
    function applyFrame(_frames : ReadOnlyArray<SpriteFrameResource>, _index : Int)
    {
        final frame = _frames[_index];

        (cast onFrame : Subject<Int>).onNext(_index);

        uv(frame.u1, frame.v1, frame.u2, frame.v2);

        resize(frame.width, frame.height);
    }
}

class AnimationNotFoundException extends Exception
{
    public function new(_name : String)
    {
        super('Animation set "$_name" does not exist in the sprite');
    }
}

class OutOfRangeException extends Exception
{
    public function new(_index : Int, _max : Int)
    {
        super(if (_index < 0) '$_index is less than 0' else '$_index is greater than or equal to $_max');
    }
}