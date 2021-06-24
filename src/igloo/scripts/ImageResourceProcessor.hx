import igloo.processors.PackedAsset;
import haxe.Exception;
import haxe.io.Output;
import igloo.processors.PackRequest;
import igloo.processors.AssetRequest;
import igloo.processors.ProcessedAsset;
import igloo.processors.IAssetProcessor;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;

using igloo.utils.OutputUtils;

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
		
		return new AssetRequest(_asset.id, 0, Pack(Image(absPath)));
	}

	public function write(_ctx : ParcelContext, _writer : Output, _asset : ProcessedAsset<Int>)
	{
		switch _asset.response
		{
			case Packed(packed):
				final frame = packed.toAsset();

				// Writes the resources ID.
				_writer.writePrefixedString(_asset.id);

				// Write the ID of the page resource this frame is within.
				_writer.writePrefixedString(frame.pageName);

				// Write UV information for the packed frame.
				_writer.writeInt32(frame.x);
				_writer.writeInt32(frame.y);
				_writer.writeInt32(frame.w);
				_writer.writeInt32(frame.h);

				_writer.writeFloat(frame.u1);
				_writer.writeFloat(frame.v1);
				_writer.writeFloat(frame.u2);
				_writer.writeFloat(frame.v2);
			case NotPacked:
				throw new Exception('Images can only be packed');
		}
	}
}