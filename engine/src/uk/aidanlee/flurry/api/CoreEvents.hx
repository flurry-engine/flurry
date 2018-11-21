package uk.aidanlee.flurry.api;

/**
 * These are the core event strings which are emitted by the flurry engine.
 * Any additional part of the engine which has access to the central event bus can listen to these events.
 */
enum abstract CoreEvents(String) from String to String
{
    var Init          = 'flurry-core-ev-init';
    
    var Ready         = 'flurry-core-ev-ready';

    var PreUpdate     = 'flurry-core-ev-pre-update';

    var Update        = 'flurry-core-ev-update';

    var PostUpdate    = 'flurry-core-ev-post-update';

    var Shutdown      = 'flurry-core-ev-shutdown';
}
