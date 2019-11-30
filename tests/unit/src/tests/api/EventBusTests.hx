package tests.api;

import uk.aidanlee.flurry.api.EventBus;
import buddy.BuddySuite;

using buddy.Should;

class EventBusTests extends BuddySuite
{
    public function new()
    {
        describe('EventBus', {
            it('Allows you to listen to a named event', {
                var event = new EventBus();
                var id    = event.listen('event', _data -> _data);

                id.should.beType(Int);
            });

            it('Allows you to unlisten from a named event', {
                var event = new EventBus();
                var id    = event.listen('event', _data -> _data);

                event.unlisten(id).should.be(true);
            });

            it('Can queue a event to be fired at the beginning of the next process', {
                var count = 0;
                var event = new EventBus();
                var id1   = event.listen('event', _data -> count++);
                var id2   = event.listen('event', _data -> count++);

                event.unlisten(id1);
                event.queue('event', 0);
                event.process();

                id1.should.beType(Int);
                id2.should.beType(Int);
                count.should.be(1);
            });

            it('Can remove an event from the event queue', {
                var count = 0;
                var event = new EventBus();
                event.listen('event', _data -> count++);

                var id1 = event.queue('event', 0);
                var id2 = event.queue('event', 0);
                var id3 = event.queue('event', 0);
                event.dequeue(id1).should.be(true);
                event.process();

                id1.should.beType(Int);
                id2.should.beType(Int);
                id3.should.beType(Int);
                count.should.be(2);
            });

            it('Can fire an event immediately calling all listeners before returning', {
                var count = 0;
                var event = new EventBus();
                var id1   = event.listen('event', _data -> count++);
                var id2   = event.listen('event', _data -> count++);
                event.unlisten(id1);
                event.fire('event', null);

                id1.should.beType(Int);
                id2.should.beType(Int);
                count.should.be(1);
            });

            it('Has a function to remove all listeners', {
                var count = 0;
                var event = new EventBus();
                event.listen('event', _data -> count++);
                event.listen('event', _data -> count++);
                event.queue('event', 0);
                event.dispose();
                event.process();

                count.should.be(0);
            });
        });
    }
}
