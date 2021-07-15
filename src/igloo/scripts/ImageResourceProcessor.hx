import igloo.processors.ResourceResponse;
import igloo.processors.RequestType;
import haxe.Exception;
import haxe.ds.Option;
import haxe.io.Output;
import igloo.utils.OneOf;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;
import igloo.processors.PackedResource;
import igloo.processors.ResourceRequest;
import igloo.processors.AssetProcessor;

using igloo.utils.OutputUtils;

class ImageResourceProcessor extends AssetProcessor<Int>
{
	override public function ids()
	{
		return [ 'png', 'jpg', 'jpeg', 'tga', 'bmp' ];
	}

	override public function pack(_ctx : ParcelContext, _asset : Asset)
	{
		final absPath = _ctx.assetDirectory.join(_asset.path);
		
		return new ResourceRequest(0, PackImage(_asset.id, absPath));
	}

	override public function write(_ctx : ParcelContext, _writer : Output, _data : Int, _response : ResourceResponse)
	{
		switch _response
		{
			case Packed(frame):
				_writer.writeInt32(frame.id);
				_writer.writeInt32(frame.pageID);
		
				// Write UV information for the packed frame.
				_writer.writeInt32(frame.x);
				_writer.writeInt32(frame.y);
				_writer.writeInt32(frame.w);
				_writer.writeInt32(frame.h);
		
				_writer.writeFloat(frame.u1);
				_writer.writeFloat(frame.v1);
				_writer.writeFloat(frame.u2);
				_writer.writeFloat(frame.v2);
			case _:
				//
		}
	}
}