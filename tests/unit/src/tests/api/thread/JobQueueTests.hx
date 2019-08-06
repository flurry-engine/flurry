package tests.api.thread;

import uk.aidanlee.flurry.api.thread.JobQueue;
import hx.concurrent.atomic.AtomicInt;
import buddy.BuddySuite;

using buddy.Should;

class JobQueueTests extends BuddySuite
{
    public function new()
    {
        describe('JobQueueTests', {
            it('allows functions to be ran on different threads', {
                var counter = new AtomicInt();
                var queue   = new JobQueue(3);
                var maxFunc = 6;

                for (i in 0...maxFunc)
                {
                    queue.queue(() -> {
                        counter.increment();
                    });
                }

                queue.wait();

                counter.value.should.be(maxFunc);
            });
        });
    }
}
