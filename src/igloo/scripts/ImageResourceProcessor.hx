import haxe.Exception;
import haxe.io.Output;
import igloo.processors.PackRequest;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.IAssetProcessor;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;

class ImageResourceProcessor implements IAssetProcessor<Int>
{
	public function new()
	{
		//
	}

	public function ids()
	{
		return [ 'png', 'jpg', 'jpeg', 'tga', 'bmp' ];
	}

	public function pack(_ctx : ParcelContext, _asset : Asset)
	{
		final absPath = _ctx.assetDirectory.join(_asset.path);
		final toPack  = [ Image(absPath) ];
		
		return new AssetRequest(_asset.id, 0, WantsPacking(toPack));
	}

	public function write(_ctx : ParcelContext, _writer : Output, _asset : ProcessedAsset<Int>)
	{
		switch _asset.response
		{
			case Packed(packed):
				// Writes the resources ID.
				_writer.writeInt32(_asset.id.length);
				_writer.writeString(_asset.id);

				// Write the number of frames.
				// Should always be 1, maybe we should assert?
				_writer.writeInt32(packed.length);

				for (asset in packed)
				{
					// Write the ID of the page resource this frame is within.
					_writer.writeInt32(asset.pageName.length);
					_writer.writeString(asset.pageName);

					// Write UV information for the packed frame.
					_writer.writeInt32(asset.x);
					_writer.writeInt32(asset.y);
					_writer.writeInt32(asset.w);
					_writer.writeInt32(asset.h);

					_writer.writeFloat(asset.u1);
					_writer.writeFloat(asset.v1);
					_writer.writeFloat(asset.u2);
					_writer.writeFloat(asset.v2);
				}
			case NotPacked:
				throw new Exception('Images can only be packed');
		}
	}
}