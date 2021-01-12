package uk.aidanlee.flurry.api.maths;

import hxrx.IObserver;
import hxrx.IObservable;
import hxrx.ISubscription;
import hxrx.observer.Observer;
import hxrx.subjects.PublishSubject;
import uk.aidanlee.flurry.api.core.Unit;

using Safety;

@:nullSafety(Off) class Transformation implements IObservable<Unit>
{
    final dirtyObserver : IObserver<Unit>;

    /**
     * Origin for all transformations.
     */
    public final origin : Vector3;

    /**
     * The local transformation.
     */
    public final local : Spatial;

    /**
     * The parent all local transformations are relative to.
     */
    public var parent (default, set) : Null<Transformation>;

    inline function set_parent(_p : Null<Transformation>) : Null<Transformation>
    {
        if (parentSubscription != null)
        {
            parentSubscription.unsubscribe();
            parentSubscription = null;
        }

        parent = _p;

        if (parent != null)
        {
            parentSubscription = parent.subscribe(dirtyObserver);
        }

        return _p;
    }

    /**
     * The real world space transformation.
     */
    public var world (get, null) : Spatial;

    inline function get_world() : Spatial
    {
        if (!ignore && dirty)
        {
            propagate();
        }

        return world;
    }

    /**
     * Local position of this transformation.
     */
    public var position (get, never) : Vector3;

    inline function get_position() : Vector3 return local.position;

    /**
     * Local rotation of this transformation.
     */
    public var rotation (get, never) : Quaternion;

    inline function get_rotation() : Quaternion return local.rotation;

    /**
     * Local scale of this transformation.
     */
    public var scale (get, never) : Vector3;

    inline function get_scale() : Vector3 return local.scale;

    /**
     * Subject which will emit values if the transformation will need to be re-calculated.
     */
    final dirtied : PublishSubject<Unit>;

    /**
     * Holds the local rotation matrix for multiplying against the local transformation matrix.
     */
    final matrixRotation : Matrix;

    /**
     * Holds the inverse origin translation.
     * Used for undoing the origin translation at the end of the local matrix construction.
     */
    final matrixOriginUndo : Matrix;

    /**
     * If set to true the `world` getter won't update before returning the matrix.
     * This is set in the propagate function to prevent infinite recursion.
     */
    var ignore : Bool;

    /**
     * If the world transformation needs to be recalculated.
     * Currently very dumb, if the local properties are accessed, set as dirty.
     */
    var dirty : Bool;

    /**
     * Subscription to the parents dirty observable.
     */
    var parentSubscription : Null<ISubscription>;

    public function new()
    {
        dirtyObserver = new Observer(setDirty, null, null);
        dirtied = new PublishSubject();
        local   = new Spatial();
        world   = new Spatial();
        origin  = new Vector3();

        matrixRotation   = new Matrix();
        matrixOriginUndo = new Matrix();

        ignore = false;
        dirty  = true;

        local.position.subscribe(dirtyObserver);
        local.rotation.subscribe(dirtyObserver);
        local.scale.subscribe(dirtyObserver);
        origin.subscribe(dirtyObserver);
    }

    /**
     * Calculate the world position of this transformation.
     */
    public function propagate()
    {
        ignore = true;

        if (parent != null)
        {
            parent.propagate();
        }

        matrixRotation.makeRotationFromQuaternion(local.rotation);
        matrixOriginUndo.makeTranslation(-origin.x, -origin.y, -origin.z);

        local.matrix.makeTranslation(origin.x, origin.y, origin.z);

        local.matrix.multiply(matrixRotation);
        local.matrix.scale(scale);
        local.matrix.setPosition(position);

        local.matrix.multiply(matrixOriginUndo);

        if (parent != null)
        {
            world.matrix.multiplyMatrices(parent.unsafe().world.matrix, local.matrix);
        }
        else
        {
            world.matrix.copy(local.matrix);
        }

        world.decompose();

        ignore = false;
        dirty  = false;
    }

    /**
     * Subscribe to the dirty event of the transformation.
     * When the transformation is dirtied the next access to the `world` property will re-calculate the matrix.
     * @param _observer 
     * @return ISubscription
     */
    public function subscribe(_observer : IObserver<Unit>) : ISubscription
    {
        return dirtied.subscribe(_observer);
    }

    function setDirty(_)
    {
        dirty = true;
        dirtied.onNext(_);
    }
}