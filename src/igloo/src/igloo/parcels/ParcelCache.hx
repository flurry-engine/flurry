package igloo.parcels;

import haxe.io.Eof;
import haxe.ds.Vector;
import hx.files.Path;

using Lambda;

class ParcelCache
{
    /**
     * Absolute path all relative paths within a assets package will be based on.
     * Used to construct the absolute path of assets to get their modification time.
     */
    final assetDir : Path;

    /**
     * Absolute path to the cached parcel file.
     * This is the actual parcel which was built.
     */
    final cachedParcel : Path;

    /**
     * Absolute path to the cached parcel hash file.
     * This text files contains multiple lines.
     * The first line is the timestamp for when the parcel was built.
     * Lines following that is a list of all the IDs of the assets within the parcel.
     */
    final cachedParcelHash : Path;

    /**
     * List of all assets we want to go into the parcel.
     * We cross reference this lists against the assets found in the parcel hash to check if its still valid.
     * If there are extra assets in the cached parcel it is not considered invalid.
     */
    final assets : Vector<Asset>;

	public function new(_assetDir, _cachedParcel, _cachedParcelHash, _assets)
    {
		assetDir         = _assetDir;
		cachedParcel     = _cachedParcel;
		cachedParcelHash = _cachedParcelHash;
        assets           = _assets;
	}

    /**
     * Checks if there is an existing parcel and if its valid.
     */
    public function isValid()
    {
        if (!cachedParcel.exists() || !cachedParcelHash.exists())
        {
            Console.debug('Cached parcel or hash file does not exist');

            return false;
        }

        // Read the time the cached parcel was created and all assets included within.
        final hashStream       = cachedParcelHash.toFile().openInput(false);
        final cachedParcelTime = Std.parseFloat(hashStream.readLine());
        final contains         = [];
        try
        {
            while (!hashStream.eof())
            {
                contains.push(hashStream.readLine());
            }
        }
        catch (e : Eof)
        {
            //
        }

        // For each asset we want to pack see if its in the cached parcel
        // If it is check its modification date against the cached parcels.
        for (asset in assets)
        {
            final found = contains.find(i -> i == asset.id);

            if (found == null)
            {
                Console.debug('asset ${ asset.id } not found in the parcel hash ${ cachedParcelHash }');

                return false;
            }
            else
            {
                final abs = assetDir.join(asset.path);
                
                if (abs.getModificationTime() >= cachedParcelTime)
                {
                    Console.debug('Modification date of ${ abs } greater than the cached parcels build time');

                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Create a hash file for the assets which were passed into the constructor.
     */
    public function writeHashFile()
    {
        final output = cachedParcelHash.toFile().openOutput(REPLACE, false);

        output.writeString('${ Date.now().getTime() }\n');
        
        for (asset in assets)
        {
            output.writeString('${ asset.id }\n');
        }

        output.close();
    }
}