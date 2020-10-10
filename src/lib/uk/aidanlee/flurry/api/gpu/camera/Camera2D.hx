package uk.aidanlee.flurry.api.gpu.camera;

import uk.aidanlee.flurry.api.gpu.camera.Camera.CameraNdcRange;
import uk.aidanlee.flurry.api.gpu.camera.Camera.CameraOrigin;
import uk.aidanlee.flurry.api.maths.Maths;
import uk.aidanlee.flurry.api.maths.Vector2;
import uk.aidanlee.flurry.api.maths.Vector3;

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
    public final size : Vector2;

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
    final shakeVector : Vector3;

    /**
     * Creates a new orthographic camera with the specific width and height.
     * @param _width  Width of the camera.
     * @param _height Height of the camera.
     */
    public function new(_width : Int, _height : Int, _origin : CameraOrigin, _ndcRange : CameraNdcRange)
    {
        super(Orthographic, _origin, _ndcRange);

        viewport       = Viewport(0, 0, _width, _height);
        size           = new Vector2(_width, _height);
        zoom           = 1;
        minimumZoom    = 0.01;
        sizeMode       = Fit;
        shaking        = false;
        shakeAmount    = 0;
        shakeMinimum   = 0.1;
        shakeVector    = new Vector3();

        rebuildCameraMatrices();
    }

    /**
     * Creates the projection matrix and combines it with the view matrix.
     */
    public function update(_dt : Float)
    {
        // Clamp the zoom
        if (zoom < minimumZoom)
        {
            zoom = minimumZoom;
        }

        switch viewport
        {
            case Viewport(_, _, _width, _height):
                final ratioX   = _width  / size.x;
                final ratioY   = _height / size.y;
                final longest  = Maths.max(ratioX, ratioY);
                final shortest = Maths.min(ratioX, ratioY);

                switch sizeMode
                {
                    case Fit:
                        transformation.scale.set(1 / (longest * zoom), 1 / (longest * zoom), 1);
                    case Cover:
                        transformation.scale.set(1 / (shortest * zoom), 1 / (shortest * zoom), 1);
                    case Contain:
                        transformation.scale.set(1 * zoom, 1 * zoom, 1);
                }
            case None:
                //
        }

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
            transformation.position.set(
                transformation.position.x + shakeVector.x,
                transformation.position.y + shakeVector.y,
                transformation.position.z + shakeVector.z
            );
        }

        rebuildCameraMatrices();
    }

    function randomPointInUnitCircle(_v : Vector3) : Vector3
    {
        var r = Maths.sqrt(Maths.random());
        var t = (-1 + (2 * Maths.random())) * (Maths.PI * 2);

        return _v.set(r * Maths.cos(t), r * Maths.sin(t), 0);
    }

    override function rebuildCameraMatrices()
    {
        switch viewport
        {
            case None: throw 'new OGL3CameraViewportNotSetException()';
            case Viewport(_x, _y, _width, _height):
                switch screenOrigin
                {
                    case TopLeft:
                        switch ndcRandge
                        {
                            case ZeroToNegativeOne:
                                projection.makeHomogeneousOrthographic(0, _width, 0, _height, -100, 100);
                            case NegativeOneToNegativeOne:
                                projection.makeHeterogeneousOrthographic(0, _width, 0, _height, -100, 100);
                        }
                    case BottomLeft:
                        switch ndcRandge
                        {
                            case ZeroToNegativeOne:
                                projection.makeHomogeneousOrthographic(0, _width, _height, 0, -100, 100);
                            case NegativeOneToNegativeOne:
                                projection.makeHeterogeneousOrthographic(0, _width, _height, 0, -100, 100);
                        }
                }
        }

        view.copy(transformation.world.matrix).invert();
    }
}
