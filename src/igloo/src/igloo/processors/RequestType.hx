package igloo.processors;

import igloo.processors.PackRequest;
import igloo.utils.OneOf;

enum RequestType
{
    /**
     * Indicate that the provided assets has data which should be packed within a atlas pages.
     * The request will either contain a single request or an array of requests.
     */
    Pack(_toPack : OneOf<PackRequest, Array<PackRequest>>);

    /**
     * Indicate that the provided asset does not need to be packed in an atlas page.
     * The request contains the name of the resource.
     */
    UnPacked(_name : String);
}