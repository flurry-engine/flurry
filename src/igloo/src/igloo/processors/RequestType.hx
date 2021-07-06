package igloo.processors;

import igloo.processors.PackRequest;
import igloo.utils.OneOf;

enum RequestType
{
    /**
     * Indicate that the provided assets has data which should be packed within a atlas pages.
     */
    Pack(_request : OneOf<PackRequest, Array<PackRequest>>);

    /**
     * Indicate that the provided asset does not need to be packed in an atlas page.
     */
    None(_id : String);
}