package uk.aidanlee.flurry.hosts;

import haxe.Timer;
import haxe.EnumFlags;
import haxe.io.Path;
import sys.io.abstractions.concrete.FileSystem;
import uk.aidanlee.flurry.api.io.FileSystemIO;
import uk.aidanlee.flurry.api.gpu.Renderer;
import uk.aidanlee.flurry.api.input.Input;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadRumble;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadDevice;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadState;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventGamepadAxis;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseWheel;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseState;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseMove;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventTextInput;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventKeyState;
import uk.aidanlee.flurry.api.input.Types.KeyModifier;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.api.display.DisplayEvents.DisplayEventData;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.schedulers.ThreadPoolScheduler;
import uk.aidanlee.flurry.api.schedulers.MainThreadScheduler;
import uk.aidanlee.flurry.macros.Host;

class CLIHost
{
    static function main()
    {
        new CLIHost();
    }

    /**
     * The users flurry application.
     * This is set by a macro by creating an instance of the class stored in the `flurry-entry-point` compiler define.
     */
    final flurry : Flurry;

    /**
     * The target frame rate of the program.
     * Not currently user definable.
     */
    final frameRate : Int;

    /**
     * Number of miliseconds between each frame.
     */
    final deltaTime : Float;

    var time : Float;

    var currentTime : Float;

    var accumulator : Float;

    function new()
    {
        // Important to set the working directory
        // Ensure we can use relative paths to read parcels.
        Sys.setCwd(Path.directory(Sys.programPath()));

        frameRate   = 60;
        deltaTime   = 1 / frameRate;
        time        = 0;
        currentTime = Timer.stamp();
        accumulator = 0;

        final events        = new FlurryEvents();
        final mainScheduler = new MainThreadScheduler();
        final taskScheduler = new ThreadPoolScheduler();

        flurry = Host.entry(events, mainScheduler, taskScheduler);

        final config = new FlurryConfig();

        flurry.config(config);

        final fileSystem    = new FileSystem();
        final renderer      = new Renderer(events.resource, events.display, config.window, config.renderer);
        final resources     = new ResourceSystem(events.resource, fileSystem, taskScheduler, mainScheduler);
        final input         = new Input(events.input);
        final display       = new Display(events.display, events.input, config);
        final io            = new FileSystemIO(config.project, fileSystem);

        flurry.ready(fileSystem, renderer, resources, input, display, io);

        while (true)
        {
            final newTime   = Timer.stamp();
            final frameTime = newTime - currentTime;

            currentTime = newTime;
            accumulator = if (frameTime > 0.25) accumulator + 0.25 else accumulator + frameTime;

            while (accumulator >= deltaTime)
            {
                flurry.update(deltaTime);

                time        = time + deltaTime;
                accumulator = accumulator - deltaTime;
            }

            flurry.tick(accumulator / deltaTime);
        }
    }
}