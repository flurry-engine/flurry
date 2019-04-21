package tests.api.display;

import uk.aidanlee.flurry.api.input.InputEvents;
import uk.aidanlee.flurry.api.input.InputEvents.InputEventMouseMove;
import uk.aidanlee.flurry.api.display.DisplayEvents;
import uk.aidanlee.flurry.api.display.Display;
import uk.aidanlee.flurry.FlurryConfig;
import buddy.BuddySuite;

using buddy.Should;

class DisplayTests extends BuddySuite
{
    public function new()
    {
        describe('Display', {
            it('Gets the initial display values from the flurry config class', {
                var config = new FlurryConfig();
                config.window.width      = 1600;
                config.window.height     = 900;
                config.window.fullscreen = true;
                config.window.vsync      = true;

                var display = new Display(new DisplayEvents(), new InputEvents(), config);
                display.width.should.be(1600);
                display.height.should.be(900);
                display.fullscreen.should.be(true);
                display.vsync.should.be(true);
                display.mouseX.should.be(0);
                display.mouseY.should.be(0);
            });

            it('Has a function which will fire an event to indicate that the window should be changed', {
                var events = new DisplayEvents();
                events.changeRequested.add(function(_data : DisplayEventChangeRequest) {
                    _data.width.should.be(1920);
                    _data.height.should.be(1080);
                    _data.fullscreen.should.be(false);
                    _data.vsync.should.be(false);
                });
                var config = new FlurryConfig();
                config.window.width      = 1600;
                config.window.height     = 900;
                config.window.fullscreen = true;
                config.window.vsync      = true;

                var display = new Display(events, new InputEvents(), config);
                display.change(1920, 1080, false, false);
            });

            it('Listens to display resize events to keep the width and height values up to date', {
                var events = new DisplayEvents();
                var config = new FlurryConfig();
                config.window.width      = 1600;
                config.window.height     = 900;
                config.window.fullscreen = true;
                config.window.vsync      = true;

                var display = new Display(events, new InputEvents(), config);
                events.sizeChanged.dispatch(new DisplayEventData(1920, 1080));

                display.width.should.be(1920);
                display.height.should.be(1080);
            });

            it('Listens to mouse move events to keep the cursor values up to date', {
                var events = new InputEvents();
                var config = new FlurryConfig();
                config.window.width      = 1600;
                config.window.height     = 900;
                config.window.fullscreen = true;
                config.window.vsync      = true;

                var display = new Display(new DisplayEvents(), events, config);
                events.mouseMove.dispatch(new InputEventMouseMove(32, 32, 4, 4));

                display.mouseX.should.be(32);
                display.mouseY.should.be(32);
            });
        });
    }
}
