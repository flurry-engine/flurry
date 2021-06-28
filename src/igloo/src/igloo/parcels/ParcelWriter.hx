package igloo.parcels;

import sys.io.FileOutput;
import igloo.processors.ProcessedAsset;
import igloo.atlas.Page;
import igloo.utils.OutputUtils;
import haxe.io.Bytes;
import haxe.io.Output;

using igloo.utils.OutputUtils;

function writeParcelHeader(_output : Output)
{
    _output.writeString('PRCL');
}

/**
 * This writes a blanked out parcel table into the output stream.
 * It is blanked out as the position and length of all resources is set to zero as they are unknown
 * at the time this is called.
 * Later on we seek back to the table section of the stream and fill in the details.
 * @param _output Output object to write to.
 * @param _packed Map of all processed assets keyed by their processor.
 * @param _count Total number of assets in the map.
 */
function writeParcelTable(_output : Output, _packed : Map<String, Array<ProcessedAsset<Any>>>, _assetCount, _pageCount, _pageFormat)
{
    _output.writeString('TABL');
    _output.writeInt32(_assetCount);
    _output.writeInt32(_pageCount);
    _output.writeByte(_pageFormat);

    for (processor => processed in _packed)
    {
        for (asset in processed)
        {
            _output.writePrefixedString(asset.id);
            _output.writePrefixedString(processor);
            _output.writeInt32(0);
            _output.writeInt32(0);
        }
    }
}

/**
 * Fills in the parcel table with the position and length of all assets.
 * @param _output File output object to write to.
 * @param _packed Map of all processed assets keyed by their processor with the position and length fields set.
 */
function fillParcelTable(_output : FileOutput, _packed : Map<String, Array<ProcessedAsset<Any>>>)
{
    // Seek to the first table entry position
    _output.seek(4 + 4 + 1 + 4 + 4, SeekBegin);

    for (processor => processed in _packed)
    {
        for (asset in processed)
        {
            _output.seek(prefixedStringSize(processor) + prefixedStringSize(asset.id), SeekCur);
            _output.writeInt32(asset.position);
            _output.writeInt32(asset.length);
        }
    }
}

function writeParcelPage(_output : Output, _page : Page, _compressed : Bytes)
{
    _output.writeString('PAGE');

    // Write the unique name of the page.
    _output.writePrefixedString(_page.name);

    // Write the page's compressed image data.
    _output.writeInt32(_compressed.length);
    _output.write(_compressed);
}

function writeParcelResources(_output : Output, _id : String, _count : Int)
{
    _output.writeString('RESR');
    _output.writePrefixedString(_id);
    _output.writeInt32(_count);
}

function writeParcelFooter(_output : Output)
{
    _output.writeString('STOP');
}