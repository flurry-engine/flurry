package uk.aidanlee.flurry.api.thread;

import sys.thread.Thread;
import hx.concurrent.atomic.AtomicInt;

/**
 * Basic queue which allows running functions on separate threads and blocking until all work is finished.
 * Tries to keep synchronisation to a minimum for speed so it can be used in the rendering backends.
 */
class JobQueue
{
    /**
     * The number of active jobs.
     * Active jobs include functions currently running and queued to run.
     */
    public var activeJobs : AtomicInt;

    /**
     * All of the active threads in this job queue.
     */
    final threads : Array<Thread>;

    /**
     * The current thread index, used to assign the next queued job to a thread.
     */
    var threadIndex : Int;

    /**
     * Create a new job queue.
     * @param _threads The maximum number of threads to run.
     */
    public function new(_threads : Int)
    {
        threads      = [ for (i in 0..._threads) Thread.create(waitForWork) ];
        threadIndex  = 0;
        activeJobs   = new AtomicInt(0);
    }

    /**
     * Queue a function to run on a thread.
     * @param _fn Function to queue.
     */
    public function queue(_fn : Void->Void)
    {
        activeJobs.increment();

        threads[threadIndex].sendMessage(_fn);

        threadIndex = (threadIndex + 1) % threads.length;
    }

    /**
     * Block until all queued functions have been ran.
     */
    public function wait()
    {
        while (activeJobs.value > 0)
        {
            // bugger all
        }
    }

    /**
     * Queues a message to stop all threads.
     */
    public function stop()
    {
        for (thread in threads)
        {
            activeJobs.increment();

            thread.sendMessage(true);
        }
    }

    /**
     * Function ran on each thread.
     * 
     * Waits for a message, then runs that function. If the message is a boolean the thread will exit.
     */
    function waitForWork()
    {
        while (true)
        {
            var msg = Thread.readMessage(true);
            if (Std.is(msg, Bool))
            {
                activeJobs.decrement();

                return;
            }

            (msg : Void->Void)();
            
            activeJobs.decrement();
        }
    }
}
