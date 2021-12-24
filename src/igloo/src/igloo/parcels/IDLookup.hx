package igloo.parcels;

import haxe.Exception;
import igloo.processors.ProcessedResource;

class IDLookup
{
    final resources : Map<String, Array<ProcessedResource<Any>>>;

    public function new(_resources)
    {
        resources = _resources;
    }

    public function lookup(_name)
    {
        for (processed in resources)
        {
            for (resource in processed)
            {
                if (resource.name == _name)
                {
                    return resource.id;
                }
            }
        }

        throw new Exception('Unable to find an ID for resource $_name');
    }
}