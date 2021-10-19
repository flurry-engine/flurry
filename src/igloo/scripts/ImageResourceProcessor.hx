import igloo.utils.OneOf;
import haxe.Exception;
import haxe.ds.Either;
import haxe.io.Output;
import igloo.parcels.Asset;
import igloo.parcels.ParcelContext;
import igloo.processors.RequestType;
import igloo.processors.AssetProcessor;
import igloo.processors.ResourceRequest;
import igloo.processors.ProcessedResource;

class ImageResourceProcessor extends AssetProcessor<Int>
{
	override public function ids()
	{
		return [ 'png', 'jpg', 'jpeg', 'tga', 'bmp' ];
	}

	override public function pack(_ctx : ParcelContext, _asset : Asset) : OneOf<ResourceRequest<Int>, Array<ResourceRequest<Int>>>
	{
		final absPath = _ctx.assetDirectory.join(_asset.path);
		
		return new ResourceRequest(_asset.id, 0, Some(PackImage(absPath)));
	}

	override public function write(_ctx : ParcelContext, _writer : Output, _resource : ProcessedResource<Int>)
	{
		switch _resource.response
		{
			case Some(Left(frame)):
				_writer.writeInt32(_resource.id);
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
				throw new Exception('ImageResourceProcessor can only operate on packed responses');
		}
	}
}