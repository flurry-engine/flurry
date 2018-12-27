package tests.api;

import buddy.BuddySuite;

class EventBusTests extends BuddySuite
{
    public function new()
    {
        describe('EventBus', {
            it('Allows you to listen to a named event', {
                //
            });

            it('Allows you to unlisten from a named event', {
                //
            });

            it('Can queue a event to be fired at the beginning of the next process', {
                //
            });

            it('Can remove an event from the event queue', {
                //
            });

            it('Can fire an event immediately calling all listeners before returning', {
                //
            });

            it('Has a function to process all queued events', {
                //
            });

            it('Has a function to remove all listeners', {
                //
            });
        });
    }
}