package igloo.parcels;

using Safety;

/**
 * The ID provider is used when assets and pages want a unique ID.
 * Instead of generating a unique ID we increment an integer starting from 0.
 * This allows the assets to be stored in a flat array of the exact size.
 * 
 * When a parcel is invalidated all of the IDs used in it are reclaimed and returned before
 * incrementing the currentID. The provider should be constructed with an initial value of 0
 * or the maximum ID + 1 of the valid cached parcels.
 */
class IDProvider
{
    var currentID : Int;

    final reclaimed : Array<Int>;

    public function new(_initial)
    {
        currentID = _initial;
        reclaimed = [];
    }

    /**
     * Returns the next free ID.
     */
    public function id()
    {
        if (reclaimed.length > 0)
        {
            return reclaimed.shift().unsafe();
        }

        return currentID++;
    }

    /**
     * Add the provided ID as free.
     * @param _id ID to reclaim.
     */
    public function reclaim(_id : Int)
    {
        reclaimed.push(_id);
    }
}