
enum abstract Platform(String) from String to String
{
    final Windows = 'windows';
    final Mac = 'mac';
    final Linux = 'linux';
}

enum Backend
{
    Snow;
    Sdl;
    Kha;
}

enum BuildProfile
{
    Debug;
    Release;
}

enum SnowRuntime
{
    Desktop;
    Cli;
    Custom(_package : String);
}

typedef Project = {
    /**
     * The app class controls build configurations specific to the binary/app output of a project.
     */
    final app : App;

    /**
     * Meta data holds information about the overall project.
     */
    final ?meta : Meta;

    /**
     * The build class controls build specific configurations and files.
     */
    final ?build : Building;

    /**
     * List of directories relative to the build file and how they will be copied into the output directory relative to the binary.
     */
    final ?files : Map<String, String>;

    /**
     * List of all parcel definitions which will be generated during building.
     */
    final ?parcels : Array<String>;
}

typedef App = {
    /**
     * The output executable name.
     */
    final name : String;

    /**
     * The bundle/package/app identifier, should be unique to you / your organisation.
     */
    final namespace : String;

    /**
     * The output directory.
     */
    final output : String;

    /**
     * The main class for haxe.
     * No .hx extension, just the name.
     */
    final main : String;

    /**
     * List of local code directories for haxe to use (-cp).
     */
    final codepaths : Array<String>;

    /**
     * The runtime this app will use.
     */
    final backend : Backend;
}

typedef Meta = {
    /**
     * The name of the project.
     */
    final ?name : String;

    /**
     * The name of the author.
     */
    final ?author : String;

    /**
     * The version number of the project.
     */
    final ?version : String;
}

typedef Building = {
    /**
     * If this build will be built in debug mode.
     */
    final ?profile : BuildProfile;

    /**
     * List of haxelib dependencies.
     * The key is the haxelib name and the value is the version.
     * If null is passed as the version the current active version is used.
     * 
     * Certain libraries will be automatically passed in depeneding on the target.
     * E.g. snow desktop target will add hxcpp and snow
     */
    final ?dependencies : Array<Dependency>;

    /**
     * List of macros to run at compile time (--macro).
     */
    final ?macros : Array<String>;

    /**
     * List of defines to pass to the compiler (-Dvalue).
     */
    final ?defines : Array<Define>;

    /**
     * All snow specific build options.
     */
    final ?snow : BuildingSnow;

    /**
     * All kha specific build options.
     */
    final ?kha : BuildingKha;
}

typedef Define = {
    final def : String;

    final ?value : String;
}

typedef Dependency = {
    final lib : String;

    final ?version : String;
}

typedef BuildingSnow = {
    /**
     * The name of the runtime to use.
     * If not set a runtime is chosen based on the target.
     */
    final ?runtime : SnowRuntime;

    /**
     * The log level to use.
     */
    final ?log : Int;
}

typedef BuildingKha = {
    //
}