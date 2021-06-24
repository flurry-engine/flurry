package igloo.processors;

import igloo.utils.OneOfPackRequest;

enum RequestType
{
    /**
     * Indicate that the provided assets has data which should be packed within a atlas pages.
     */
    Pack(request : OneOfPackRequest);

    /**
     * Indicate that the provided asset does not need to be packed in an atlas page.
     */
    None;
}