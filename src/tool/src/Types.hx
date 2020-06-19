abstract Unit(Dynamic)
{
    public static final value = new Unit();

    function new()
    {
        this = null;
    }
}

enum Result<T>
{
    Success(data : T);
    Failure(message : String);
}

enum abstract Platform(String) from String to String
{
    var Windows = 'windows';
    var Mac = 'mac';
    var Linux = 'linux';
}

enum Backend
{
    Snow;
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
    var app : App;

    /**
     * Meta data holds information about the overall project.
     */
    var ?meta : Meta;

    /**
     * The build class controls build specific configurations and files.
     */
    var ?build : Building;

    /**
     * List of directories relative to the build file and how they will be copied into the output directory relative to the binary.
     */
    var ?files : Map<String, String>;

    /**
     * List of all parcel definitions which will be generated during building.
     */
    var ?parcels : Array<String>;
}

typedef App = {
    /**
     * The output executable name.
     */
    var name : String;

    /**
     * The bundle/package/app identifier, should be unique to you / your organisation.
     */
    var namespace : String;

    /**
     * The output directory.
     */
    var output : String;

    /**
     * The main class for haxe.
     * No .hx extension, just the name.
     */
    var main : String;

    /**
     * List of local code directories for haxe to use (-cp).
     */
    var codepaths : Array<String>;

    /**
     * The runtime this app will use.
     */
    var backend : Backend;
}

typedef Meta = {
    /**
     * The name of the project.
     */
    var ?name : String;

    /**
     * The name of the author.
     */
    var ?author : String;

    /**
     * The version number of the project.
     */
    var ?version : String;
}

typedef Building = {
    /**
     * If this build will be built in debug mode.
     */
    var ?profile : BuildProfile;

    /**
     * List of haxelib dependencies.
     * The key is the haxelib name and the value is the version.
     * If null is passed as the version the current active version is used.
     * 
     * Certain libraries will be automatically passed in depeneding on the target.
     * E.g. snow desktop target will add hxcpp and snow
     */
    var ?dependencies : Array<Dependency>;

    /**
     * List of macros to run at compile time (--macro).
     */
    var ?macros : Array<String>;

    /**
     * List of defines to pass to the compiler (-Dvalue).
     */
    var ?defines : Array<Define>;

    /**
     * All snow specific build options.
     */
    var ?snow : BuildingSnow;

    /**
     * All kha specific build options.
     */
    var ?kha : BuildingKha;
}

typedef Define = {
    var def : String;

    var ?value : String;
}

typedef Dependency = {
    var lib : String;

    var ?version : String;
}

typedef BuildingSnow = {
    /**
     * The name of the runtime to use.
     * If not set a runtime is chosen based on the target.
     */
    var ?runtime : SnowRuntime;

    /**
     * The log level to use.
     */
    var ?log : Int;
}

typedef BuildingKha = {
    //
}