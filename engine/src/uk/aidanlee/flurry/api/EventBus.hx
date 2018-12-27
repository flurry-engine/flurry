package uk.aidanlee.flurry.api;

import uk.aidanlee.flurry.api.maths.Hash;

/**
 * All callback functions must contain one argument return void.
 */
typedef EventFunction = Dynamic->Void;

/**
 * Event bus which can fire and queue named events.
 */
class EventBus
{
    /**
     * Queue of all events to be fired new processing step.
     */
    final eventQueue : Array<EventObject>;

    /**
     * Stores all connections in this event bus.
     */
    final eventConnections : Map<Int, EventConnection>;

    /**
     * All event connections keyed by the event they listen to.
     */
    final eventSlots : Map<String, Array<EventConnection>>;

    public function new()
    {
        eventQueue       = [];
        eventConnections = new Map();
        eventSlots       = new Map();
    }

    /**
     * Fire off any events in the queue.
     */
    public function process()
    {
        while (eventQueue.length > 0)
        {
            var event = eventQueue.pop();
            
            fire(event.name, event.properties);
        }
    }

    /**
     * Remove all events and listeners.
     */
    public function dispose()
    {
        eventQueue.resize(0);

        for (key in eventConnections.keys())
        {
            eventConnections.remove(key);
        }

        for (key in eventSlots.keys())
        {
            eventSlots.remove(key);
        }
    }

    /**
     * Listen to a specific named event.
     * @param _event      The event to listen to.
     * @param _properties Callback function.
     * @return listener ID.
     */
    public function listen<T>(_name : String, _listener : (_data : T) -> Void) : Int
    {
        var id         = Hash.uniqueHash();
        var connection = new EventConnection(id, _name, _listener);

        eventConnections.set(id, connection);

        if (!eventSlots.exists(_name))
        {
            eventSlots.set(_name, [ connection ]);
        }
        else
        {
            eventSlots.get(_name).push(connection);
        }

        return id;
    }

    /**
     * Stop listening to a specific named event.
     * @param _eventID listener ID.
     * @return If the listener was successfully removed.
     */
    public function unlisten(_eventID : Int) : Bool
    {
        if (eventConnections.exists(_eventID))
        {
            var connection = eventConnections.get(_eventID);
            var eventSlot  = eventSlots.get(connection.name);

            if (eventSlot != null)
            {
                eventSlot.remove(connection);
                return true;
            }
        }

        return false;
    }

    /**
     * Queue a new event.
     * @param _event      Event to queue.
     * @param _properties Data to go with the event.
     * @return Listener ID
     */
    @:generic
    public function queue<T>(_event : String, _properties : T = null) : Int
    {
        var id = Hash.uniqueHash();

        eventQueue.push(new EventObject(id, _event, _properties));

        return id;
    }

    /**
     * Remove an event from the queue.
     * @param _eventID Listner ID of the event to remove.
     * @return If the event was successfully removed.
     */
    public function dequeue(_eventID : Int) : Bool
    {
        var event = Lambda.find(eventQueue, _ev -> _ev.id == _eventID);
        if (event != null)
        {
            eventQueue.remove(event);
            return true;
        }

        return false;
    }

    /**
     * Fire an event, immediately calling all listeners.
     * @param _event      Event to fire.
     * @param _properties Data of the event.
     * @return If any listeners were called.
     */
    public function fire<T>(_event : String, _properties : T = null) : Bool
    {
        if (eventSlots.exists(_event))
        {
            for (connection in eventSlots.get(_event))
            {
                connection.listener(_properties);
            }

            return true;
        }

        return false;
    }
}

private class EventConnection
{
    public final id : Int;

    public final name : String;

    public final listener : EventFunction;

    public function new(_id : Int, _name : String, _listener : EventFunction)
    {
        id       = _id;
        name     = _name;
        listener = _listener;
    }
}

private class EventObject
{
    public final id : Int;

    public final name : String;

    public final properties : Dynamic;

    public function new(_id : Int, _name : String, _properties : Dynamic)
    {
        id         = _id;
        name       = _name;
        properties = _properties;
    }
}
