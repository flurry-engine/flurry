package uk.aidanlee.flurry.api.io;

import haxe.ds.Option;
import haxe.io.Bytes;

/**
 * Interface provides a variety of functions for checking, getting, and setting data stored in a project specific location.
 */
interface IIO
{
    /**
     * Where all the preferences are stored.
     * What this string represents will depend on the implementation.
     * @return String
     */
    function preferencePath() : String;

    /**
     * Check if the preferences has a value of the specified key.
     * @param _key Unique preference key.
     * @return Bool
     */
    function has(_key : String) : Bool;

    /**
     * Remove the data stored at the preference key.
     * @param _key Unique preference key.
     */
    function remove(_key : String) : Void;

    /**
     * Get the string value of the preference.
     * @param _key Unique preference key.
     * @return Option<String>
     */
    function getString(_key : String) : Option<String>;

    /**
     * Get the bytes value of the preference.
     * @param _key Unique preference key.
     * @return Option<Bytes>
     */
    function getBytes(_key : String) : Option<Bytes>;

    /**
     * Set the value of the preference to the provided string.
     * @param _key Unique preference key.
     * @param _val New value.
     */
    function setString(_key : String, _val : String) : Void;

    /**
     * Set the value of the preference to the provided bytes.
     * @param _key Unique preference key.
     * @param _val New value.
     */
    function setBytes(_key : String, _val : Bytes) : Void;
}