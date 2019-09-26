package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.maths.Rectangle;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.maths.Transformation;

/**
 * All of the different camera size modes.
 */
enum SizeMode {

    /**
     * Fit the size into the cameras viewport. (may cause letter / pillar boxing)
     */
    Fit;
    
    /**
     * Cover the viewport with the size. (may cause cropping)
     */
    Cover;

    /**
     * Contain the camera. (stretch to fit the viewport)
     */
    Contain;
}

/**
 * Orthographic camera.
 */
class Camera2D extends Camera
{
    /**
     * The virtual size of this camera.
     * Size relative within the world space, not the view space.
     */
    public final size : Vector;

    /**
     * //
     */
    public final transformation : Transformation;

    /**
     * 
     */
    public var dirty : Bool;

    /**
     * 
     */
    public var position (get, never) : Vector;

    inline function get_position() : Vector return transformation.position;

    /**
     * 
     */
    public var scale (get, never) : Vector;

    inline function get_scale() : Vector return transformation.scale;

    /**
     * 
     */
    public var origin (get, never) : Vector;

    inline function get_origin() : Vector return transformation.origin;
    
    /**
     * Size mode determines how the camera will scale the view.
     */
    public var sizeMode : SizeMode;

    /**
     * The zoom of this orthographic camera.
     */
    public var zoom : Float;

    /**
     * The minimum zoom value this camera is allowed.
     */
    public var minimumZoom : Float;

    /**
     * If the camera is currently shaking.
     */
    public var shaking : Bool;

    /**
     * The initial maximum shake amount.
     */
    public var shakeAmount : Float;

    /**
     * The minimum shake value until the camera stops shaking.
     */
    public var shakeMinimum : Float;

    /**
     * Vector used to store the shake directions to add to the cameras position.
     */
    final shakeVector : Vector;

    /**
     * Creates a new orthographic camera with the specific width and height.
     * @param _width  Width of the camera.
     * @param _height Height of the camera.
     */
    public function new(_width : Float, _height : Float)
    {
        super(Orthographic);

        viewport       = new Rectangle(0, 0, _width, _height);
        size           = new Vector(_width, _height);
        transformation = new Transformation();
        zoom           = 1;
        minimumZoom    = 0.01;
        sizeMode       = Fit;
        shaking        = false;
        shakeAmount    = 0;
        shakeMinimum   = 0.1;
        shakeVector    = new Vector();

        update();
    }

    /**
     * Creates the projection matrix and combines it with the view matrix.
     */
    public function update()
    {
        // Clamp the zoom
        if (zoom < minimumZoom)
        {
            zoom = minimumZoom;
        }
        
        // Update the position and virtual view size according to the scale mode.
        var ratioX   = viewport.w / size.x;
        var ratioY   = viewport.h / size.y;
        var shortest = Maths.max(ratioX, ratioY);
        var longest  = Maths.min(ratioX, ratioY);

        switch (sizeMode)
        {
            case Fit    : ratioX = ratioY = longest;
            case Cover  : ratioX = ratioY = shortest;
            case Contain: // Uses actual size.
        }

        transformation.scale.x = 1 / (ratioX * zoom);
        transformation.scale.y = 1 / (ratioY * zoom);

        // Apply any shaking
        if (shaking)
        {
            // Get a random direction and apply the shake scaling
            randomPointInUnitCircle(shakeVector);

            shakeVector.x *= shakeAmount;
            shakeVector.y *= shakeAmount;
            shakeVector.z *= shakeAmount;

            // Slowly fade out the shaking
            shakeAmount *= 0.9;
            if (shakeAmount <= shakeMinimum)
            {
                shakeAmount = 0;
                shaking     = false;
            }

            // Update the shake position
            transformation.position.set_xyz(
                transformation.position.x + shakeVector.x,
                transformation.position.y + shakeVector.y,
                transformation.position.z + shakeVector.z
            );
        }

        dirty = true;
    }

    /**
     * Returns a random unit vector.
     * @return Vector
     */
    function randomPointInUnitCircle(_v : Vector) : Vector
    {
        var r = Maths.sqrt(Maths.random());
        var t = (-1 + (2 * Maths.random())) * (Maths.PI * 2);

        return _v.set_xy(r * Maths.cos(t), r * Maths.sin(t));
    }
}
