package igloo.processors;

enum AssetResponse
{
    Packed(packed : Array<PackedAsset>);
    NotPacked;
}