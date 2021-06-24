package igloo.processors;

import igloo.utils.OneOfPackedAsset;

enum AssetResponse
{
    Packed(packed : OneOfPackedAsset);
    NotPacked;
}