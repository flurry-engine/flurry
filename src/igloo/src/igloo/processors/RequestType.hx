package igloo.processors;

enum RequestType
{
    /**
     * Indicate that the provided assets has data which should be packed within a atlas pages.
     */
    WantsPacking(images : Array<PackRequest>);

    /**
     * Indicate that the provided asset does not need to be packed in an atlas page.
     */
    NoPacking;
}