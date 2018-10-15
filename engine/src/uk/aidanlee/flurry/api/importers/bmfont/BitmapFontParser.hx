package uk.aidanlee.flurry.api.importers.bmfont;

import uk.aidanlee.flurry.api.importers.bmfont.BitmapFontData;

/**
 * Parses and returns an anonymous structure of font data based on a font file description.
 * Right now it can only read plain text .fnt BMFont files.
 */
class BitmapFontParser
{
    /**
     * Parse the string containing BMFont data.
     * @param _fontData String of font data to parse.
     * @return BitmapFontData
     */
    public static function parse(_fontData : String) : BitmapFontData
    {
        if (_fontData.length == 0)
        {
            throw 'BMFont Parser : Font data string is empty';
        }

        // Split the input string into its lines.
        var lines = _fontData.split('\n');
        var first = lines[0];

        // Check if the first 4 characters is 'info', it not its not a valid BMFont string.
        if (StringTools.ltrim(first).substr(0, 4) != 'info')
        {
            throw 'BMFont Parser : Invalid font data for parser. Format should be plain text .fnt file';
        }

        var info = new BitmapFontData(
            null,
            0,
            0,
            new Array<{ id : Int, file : String }>(),
            0,
            0,
            new Map<Int, Character>(),
            0,
            new Map<Int, Map<Int, Float>>()
        );

        var regex = new EReg('\\s+', 'gi');
        for (line in lines)
        {
            // Parse each line, splitting by any amount of space characters
            var tokens = regex.split(line);
            parseTokens(tokens.shift(), tokens, info);
        }

        return info;
    }

    /**
     * Parses all the tokens from a line in the font descriptor file.
     * @param _majorToken The first token in that line, is used as an identifier for what to do with following tokens.
     * @param _subTokens  Tokens following the major one contain sub information based on the major token.
     * @param _fontData   Strcture to insert parsed data into.
     */
    static function parseTokens(_majorToken : String, _subTokens : Array<String>, _fontData : BitmapFontData)
    {
        // Map out all following tokens so they can be accessed by string.
        var items = tokeniseLine(_subTokens);

        // Decided what to do based on the primary token.
        switch (_majorToken)
        {
            case 'info':
                _fontData.face      = unquote(items['face']);
                _fontData.pointSize = Std.parseFloat(items['size']);

            case 'common':
                _fontData.lineHeight = Std.parseFloat(items['lineHeight']);
                _fontData.baseSize   = Std.parseFloat(items['base']);

            case 'page':
                _fontData.pages.push({
                    id   : Std.parseInt(items['id']),
                    file : StringTools.trim(unquote(items['file']))
                });

            case 'chars':
                _fontData.charCount = Std.parseInt(items['count']);

            case 'char':
                var char = new Character(
                    Std.parseInt(items['id']),
                    Std.parseInt(items['x']),
                    Std.parseInt(items['y']),
                    Std.parseFloat(items['width']),
                    Std.parseFloat(items['height']),
                    Std.parseFloat(items['xoffset']),
                    Std.parseFloat(items['yoffset']),
                    Std.parseFloat(items['xadvance']),
                    Std.parseInt(items['page'])
                );

                _fontData.chars.set(char.id, char);

            case 'kernings':
                _fontData.kerningCount = Std.parseInt(items['count']);

            case 'kerning':
                var first  = Std.parseInt(items['first']);
                var second = Std.parseInt(items['second']);
                var amount = Std.parseFloat(items['amount']);

                var map = _fontData.kernings.get(first);
                if (map == null)
                {
                    map = new Map<Int, Float>();
                    _fontData.kernings.set(first, map);
                }

                map.set(second, amount);
        }
    }

    /**
     * Map out a set of tokens. Each token is 'id=value' where the id is the key in the map and the value is the value.
     * @param _tokens Tokens to parse.
     * @return Map<String, String>
     */
    static function tokeniseLine(_tokens : Array<String>) : Map<String, String>
    {
        var itemMap = new Map<String, String>();

        for (token in _tokens)
        {
            var items = token.split('=');
            itemMap.set(items[0], items[1]);
        }

        return itemMap;
    }

    /**
     * Remove quotes from a string.
     * @param _s String to remove quotes from.
     * @return String
     */
    static function unquote(_s : String) : String
    {
        if (_s.indexOf('"') != -1)
        {
            _s = StringTools.replace(_s, '"', '');
        }

        return _s;
    }
}
