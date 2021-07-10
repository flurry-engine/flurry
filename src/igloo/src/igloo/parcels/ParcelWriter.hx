package igloo.parcels;

import igloo.atlas.Page;
import haxe.io.Bytes;
import haxe.io.Output;

using igloo.utils.OutputUtils;

function writeParcelHeader(_output : Output, _pageCount, _pageFormat)
{
    _output.writeString('PRCL');
    _output.writeInt32(_pageCount);
    _output.writeByte(_pageFormat);
}

function writeParcelPage(_output : Output, _page : Page, _compressed : Bytes)
{
    _output.writeString('PAGE');

    // Write the unique name of the page.
    _output.writeInt32(_page.id);

    // Write the page's compressed image data.
    _output.writeInt32(_compressed.length);
    _output.write(_compressed);
}

/**
 * Writes header info into the stream about a processor.
 * @param _output Stream object.
 * @param _proc Processor id.
 * @param _invocations Number of times the pack function of the processor was called (each invocation can produced multiple resources).
 */
function writeParcelProcessor(_output : Output, _proc : String, _invocations : Int)
{
    _output.writeString('PROC');
    _output.writePrefixedString(_proc);
    _output.writeInt32(_invocations);
}

function writeParcelFooter(_output : Output)
{
    _output.writeString('STOP');
}