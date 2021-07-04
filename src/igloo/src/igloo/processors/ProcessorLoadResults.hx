package igloo.processors;

class ProcessorLoadResult
{
    public final loaded : Map<String, AssetProcessor<Any>>;

    public final names : Array<String>;

    public final recompiled : Array<String>;

    public function new()
    {
        loaded     = [];
        names      = [];
        recompiled = [];
    }
}