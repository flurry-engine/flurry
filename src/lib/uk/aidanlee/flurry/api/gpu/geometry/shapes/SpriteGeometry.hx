package uk.aidanlee.flurry.api.gpu.geometry.shapes;

import hxrx.IObservable;
import hxrx.subjects.PublishSubject;
import uk.aidanlee.flurry.api.gpu.state.BlendState;
import uk.aidanlee.flurry.api.gpu.state.ClipState;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.GeometryUniforms;
import uk.aidanlee.flurry.api.gpu.geometry.Geometry.GeometryShader;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector3;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteFrameResource;
import haxe.Exception;
import haxe.ds.ReadOnlyArray;

using Safety;

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
    public var width (get, never) : Float;

    inline function get_width() return currentAnimation[index].width * scale.x;

    /**
     * The current height of the sprite.
     * Current frame height multiplied by the y scale.
     */
    public var height (get, never) : Float;

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

        animations       = _options.sprite.animations;
        scale.x          = _options.xScale;
        scale.y          = _options.yScale;
        origin.x         = _options.xOrigin;
        origin.y         = _options.yOrigin;
        angle            = _options.angle;
        speed            = _options.speed;
        index            = 0;
        time             = 0;
        playing          = false;
        currentAnimation = [];
        onAnimation      = new PublishSubject<String>();
        onFrame          = new PublishSubject<Int>();

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
            currentAnimation = animations[_name].unsafe();
            playing          = true;
            index            = 0;
            time             = 0;

            (cast onAnimation : PublishSubject<String>).onNext(_name);

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

        (cast onFrame : PublishSubject<Int>).onNext(_index);

        uv(frame.u1, frame.v1, frame.u2, frame.v2);

        resize(frame.width, frame.height);
    }
}

@:structInit class SpriteOptions
{
    /**
     * Sprite data for this geometry.
     */
    public final sprite : SpriteResource;

    /**
     * Initial animation to play.
     */
    public final animation : String;

    /**
     * Initial x position of the sprite.
     */
    public final x = 0.0;

    /**
     * Initial y position of the sprite.
     */
    public final y = 0.0;

    /**
     * Scale multiplier for the sprites width.
     */
    public final xScale = 1.0;

    /**
     * Scale multiplier for the sprites height.
     */
    public final yScale = 1.0;

    /**
     * The x origin for all translations and rotations.
     * Value is a pixel location into the sprites image. This is uneffected by any scaling.
     */
    public final xOrigin = 0;

    /**
     * The y origin for all translations and rotations.
     * Value is a pixel location into the sprites image. This is uneffected by any scaling.
     */
    public final yOrigin = 0;

    /**
     * Speed multiplier for animation playing.
     */
    public final speed = 1.0;

    /**
     * Initial angle in degrees for the sprite.
     */
    public final angle = 0.0;

    /**
     * If the initial animation should immediately start playing.
     */
    public final playing = false;

    /**
     * Provide a custom sampler for the geometries texture.
     * If null is provided a default sampler is used.
     * Default samplers is clamp uv clipping and nearest neighbour scaling.
     */
    public final sampler = SamplerState.nearest;

    /**
     * Specify a custom shader to be used by this geometry.
     * If none is provided the batchers shader is used.
     */
    public final shader = GeometryShader.None;

    /**
     * Specify custom uniform blocks to be passed to the shader.
     * If none is provided the batchers uniforms are used.
     */
    public final uniforms = GeometryUniforms.None;
    
    /**
     * Initial depth of the geometry.
     * If none is provided 0 is used.
     */
    public final depth = 0.0;

    /**
     * Custom clip rectangle for this geometry.
     * Defaults to clipping based on the batchers camera.
     */
    public final clip = ClipState.None;

    /**
     * Provides custom blending operations for drawing this geometry.
     */
    public final blend = BlendState.none;

    /**
     * The batchers to initially add this geometry to.
     */
    public final batchers = new Array<Batcher>();
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