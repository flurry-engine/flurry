package igloo.parcels;

import igloo.atlas.Page;
import haxe.io.Bytes;
import haxe.io.Output;

function writeParcelHeader(_output : Output)
{
    _output.writeString('PRCL');
}

function writeParcelMeta(_output : Output, _pageCount, _assetCount)
{
    _output.writeInt32(_pageCount);
    _output.writeInt32(_assetCount);
}

function writeParcelPage(_output : Output, _page : Page, _compressed : Bytes)
{
    _output.writeString('PAGE');

    // Write the unique name of the page.
    _output.writeInt32(_page.name.length);
    _output.writeString(_page.name);

    // Write the page's compressed image data.
    _output.writeInt32(_compressed.length);
    _output.write(_compressed);
}

function writeParcelResources(_output : Output, _id : String, _count : Int)
{
    _output.writeString('RESR');
    _output.writeInt32(_id.length);
    _output.writeString(_id);
    _output.writeInt32(_count);
}

function writeParcelFooter(_output : Output)
{
    _output.writeString('STOP');
}