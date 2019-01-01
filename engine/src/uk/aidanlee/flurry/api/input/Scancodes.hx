package uk.aidanlee.flurry.api.input;

/**
 * The values below come directly from SDL header include files, but they aren't specific to SDL so they are used generically.
 */
class Scancodes
{
    /**
     * Convert a scancode to a readable name
     * @param _scancode Scancode number
     * @return Name string
     */
    public static function name(_scancode : Int) : String
    {
        var res = null;

        if (_scancode >= 0 && _scancode < scanecodeNames.length)
        {
            res = scanecodeNames[_scancode];
        }

        return res != null ? res : '';
    }

        //special value remains caps
    public static inline var MASK:Int                      = (1 << 30);

    public static inline var unknown : Int                 = 0;

       // Usage page 0x07
       // These values are from usage page 0x07 (USB keyboard page).

    public static inline var key_a : Int                   =  4;
    public static inline var key_b : Int                   =  5;
    public static inline var key_c : Int                   =  6;
    public static inline var key_d : Int                   =  7;
    public static inline var key_e : Int                   =  8;
    public static inline var key_f : Int                   =  9;
    public static inline var key_g : Int                   = 10;
    public static inline var key_h : Int                   = 11;
    public static inline var key_i : Int                   = 12;
    public static inline var key_j : Int                   = 13;
    public static inline var key_k : Int                   = 14;
    public static inline var key_l : Int                   = 15;
    public static inline var key_m : Int                   = 16;
    public static inline var key_n : Int                   = 17;
    public static inline var key_o : Int                   = 18;
    public static inline var key_p : Int                   = 19;
    public static inline var key_q : Int                   = 20;
    public static inline var key_r : Int                   = 21;
    public static inline var key_s : Int                   = 22;
    public static inline var key_t : Int                   = 23;
    public static inline var key_u : Int                   = 24;
    public static inline var key_v : Int                   = 25;
    public static inline var key_w : Int                   = 26;
    public static inline var key_x : Int                   = 27;
    public static inline var key_y : Int                   = 28;
    public static inline var key_z : Int                   = 29;

    public static inline var key_1 : Int                   = 30;
    public static inline var key_2 : Int                   = 31;
    public static inline var key_3 : Int                   = 32;
    public static inline var key_4 : Int                   = 33;
    public static inline var key_5 : Int                   = 34;
    public static inline var key_6 : Int                   = 35;
    public static inline var key_7 : Int                   = 36;
    public static inline var key_8 : Int                   = 37;
    public static inline var key_9 : Int                   = 38;
    public static inline var key_0 : Int                   = 39;

    public static inline var enter : Int                   = 40;
    public static inline var escape : Int                  = 41;
    public static inline var backspace : Int               = 42;
    public static inline var tab : Int                     = 43;
    public static inline var space : Int                   = 44;

    public static inline var minus : Int                   = 45;
    public static inline var equals : Int                  = 46;
    public static inline var leftbracket : Int             = 47;
    public static inline var rightbracket : Int            = 48;

        // Located at the lower left of the return
        // key on ISO keyboards and at the right end
        // of the QWERTY row on ANSI keyboards.
        // Produces REVERSE SOLIDUS (backslash) and
        // VERTICAL LINE in a US layout, REVERSE
        // SOLIDUS and VERTICAL LINE in a UK Mac
        // layout, NUMBER SIGN and TILDE in a UK
        // Windows layout, DOLLAR SIGN and POUND SIGN
        // in a Swiss German layout, NUMBER SIGN and
        // APOSTROPHE in a German layout, GRAVE
        // ACCENT and POUND SIGN in a French Mac
        // layout, and ASTERISK and MICRO SIGN in a
        // French Windows layout.

    public static inline var backslash : Int               = 49;

        // ISO USB keyboards actually use this code
        // instead of 49 for the same key, but all
        // OSes I've seen treat the two codes
        // identically. So, as an implementor, unless
        // your keyboard generates both of those
        // codes and your OS treats them differently,
        // you should generate public static inline var BACKSLASH
        // instead of this code. As a user, you
        // should not rely on this code because SDL
        // will never generate it with most (all?)
        // keyboards.

    public static inline var nonushash : Int          = 50;
    public static inline var semicolon : Int          = 51;
    public static inline var apostrophe : Int         = 52;

        // Located in the top left corner (on both ANSI
        // and ISO keyboards). Produces GRAVE ACCENT and
        // TILDE in a US Windows layout and in US and UK
        // Mac layouts on ANSI keyboards, GRAVE ACCENT
        // and NOT SIGN in a UK Windows layout, SECTION
        // SIGN and PLUS-MINUS SIGN in US and UK Mac
        // layouts on ISO keyboards, SECTION SIGN and
        // DEGREE SIGN in a Swiss German layout (Mac:
        // only on ISO keyboards); CIRCUMFLEX ACCENT and
        // DEGREE SIGN in a German layout (Mac: only on
        // ISO keyboards), SUPERSCRIPT TWO and TILDE in a
        // French Windows layout, COMMERCIAL AT and
        // NUMBER SIGN in a French Mac layout on ISO
        // keyboards, and LESS-THAN SIGN and GREATER-THAN
        // SIGN in a Swiss German, German, or French Mac
        // layout on ANSI keyboards.

    public static inline var grave : Int              = 53;
    public static inline var comma : Int              = 54;
    public static inline var period : Int             = 55;
    public static inline var slash : Int              = 56;

    public static inline var capslock : Int           = 57;

    public static inline var f1 : Int                 = 58;
    public static inline var f2 : Int                 = 59;
    public static inline var f3 : Int                 = 60;
    public static inline var f4 : Int                 = 61;
    public static inline var f5 : Int                 = 62;
    public static inline var f6 : Int                 = 63;
    public static inline var f7 : Int                 = 64;
    public static inline var f8 : Int                 = 65;
    public static inline var f9 : Int                 = 66;
    public static inline var f10 : Int                = 67;
    public static inline var f11 : Int                = 68;
    public static inline var f12 : Int                = 69;

    public static inline var printscreen : Int        = 70;
    public static inline var scrolllock : Int         = 71;
    public static inline var pause : Int              = 72;

        // insert on PC, help on some Mac keyboards (but does send code 73, not 117)
    public static inline var insert : Int             = 73;
    public static inline var home : Int               = 74;
    public static inline var pageup : Int             = 75;
    public static inline var delete : Int             = 76;
    public static inline var end : Int                = 77;
    public static inline var pagedown : Int           = 78;
    public static inline var right : Int              = 79;
    public static inline var left : Int               = 80;
    public static inline var down : Int               = 81;
    public static inline var up : Int                 = 82;

        // num lock on PC, clear on Mac keyboards
    public static inline var numlockclear : Int       = 83;
    public static inline var kp_divide : Int          = 84;
    public static inline var kp_multiply : Int        = 85;
    public static inline var kp_minus : Int           = 86;
    public static inline var kp_plus : Int            = 87;
    public static inline var kp_enter : Int           = 88;
    public static inline var kp_1 : Int               = 89;
    public static inline var kp_2 : Int               = 90;
    public static inline var kp_3 : Int               = 91;
    public static inline var kp_4 : Int               = 92;
    public static inline var kp_5 : Int               = 93;
    public static inline var kp_6 : Int               = 94;
    public static inline var kp_7 : Int               = 95;
    public static inline var kp_8 : Int               = 96;
    public static inline var kp_9 : Int               = 97;
    public static inline var kp_0 : Int               = 98;
    public static inline var kp_period : Int          = 99;

        // This is the additional key that ISO
        // keyboards have over ANSI ones,
        // located between left shift and Y.
        // Produces GRAVE ACCENT and TILDE in a
        // US or UK Mac layout, REVERSE SOLIDUS
        // (backslash) and VERTICAL LINE in a
        // US or UK Windows layout, and
        // LESS-THAN SIGN and GREATER-THAN SIGN
        // in a Swiss German, German, or French
        // layout.
    public static inline var nonusbackslash : Int     = 100;

        // windows contextual menu, compose
    public static inline var application : Int        = 101;

        // The USB document says this is a status flag,
        // not a physical key - but some Mac keyboards
        // do have a power key.
    public static inline var power : Int              = 102;
    public static inline var kp_equals : Int          = 103;
    public static inline var f13 : Int                = 104;
    public static inline var f14 : Int                = 105;
    public static inline var f15 : Int                = 106;
    public static inline var f16 : Int                = 107;
    public static inline var f17 : Int                = 108;
    public static inline var f18 : Int                = 109;
    public static inline var f19 : Int                = 110;
    public static inline var f20 : Int                = 111;
    public static inline var f21 : Int                = 112;
    public static inline var f22 : Int                = 113;
    public static inline var f23 : Int                = 114;
    public static inline var f24 : Int                = 115;
    public static inline var execute : Int            = 116;
    public static inline var help : Int               = 117;
    public static inline var menu : Int               = 118;
    public static inline var select : Int             = 119;
    public static inline var stop : Int               = 120;

        // redo
    public static inline var again : Int              = 121;
    public static inline var undo : Int               = 122;
    public static inline var cut : Int                = 123;
    public static inline var copy : Int               = 124;
    public static inline var paste : Int              = 125;
    public static inline var find : Int               = 126;
    public static inline var mute : Int               = 127;
    public static inline var volumeup : Int           = 128;
    public static inline var volumedown : Int         = 129;

        // not sure whether there's a reason to enable these
    //  public static inline var lockingcapslock = 130,
    //  public static inline var lockingnumlock = 131,
    //  public static inline var lockingscrolllock = 132,

    public static inline var kp_comma : Int           = 133;
    public static inline var kp_equalsas400 : Int     = 134;

        // used on Asian keyboards; see footnotes in USB doc
    public static inline var international1 : Int     = 135;
    public static inline var international2 : Int     = 136;

        // Yen
    public static inline var international3 : Int     = 137;
    public static inline var international4 : Int     = 138;
    public static inline var international5 : Int     = 139;
    public static inline var international6 : Int     = 140;
    public static inline var international7 : Int     = 141;
    public static inline var international8 : Int     = 142;
    public static inline var international9 : Int     = 143;
        // Hangul/English toggle
    public static inline var lang1 : Int              = 144;
        // Hanja conversion
    public static inline var lang2 : Int              = 145;
        // Katakana
    public static inline var lang3 : Int              = 146;
        // Hiragana
    public static inline var lang4 : Int              = 147;
        // Zenkaku/Hankaku
    public static inline var lang5 : Int              = 148;
        // reserved
    public static inline var lang6 : Int              = 149;
        // reserved
    public static inline var lang7 : Int              = 150;
        // reserved
    public static inline var lang8 : Int              = 151;
        // reserved
    public static inline var lang9 : Int              = 152;
        // Erase-Eaze
    public static inline var alterase : Int           = 153;
    public static inline var sysreq : Int             = 154;
    public static inline var cancel : Int             = 155;
    public static inline var clear : Int              = 156;
    public static inline var prior : Int              = 157;
    public static inline var return2 : Int            = 158;
    public static inline var separator : Int          = 159;
    public static inline var out : Int                = 160;
    public static inline var oper : Int               = 161;
    public static inline var clearagain : Int         = 162;
    public static inline var crsel : Int              = 163;
    public static inline var exsel : Int              = 164;

    public static inline var kp_00 : Int              = 176;
    public static inline var kp_000 : Int             = 177;
    public static inline var thousandsseparator : Int = 178;
    public static inline var decimalseparator : Int   = 179;
    public static inline var currencyunit : Int       = 180;
    public static inline var currencysubunit : Int    = 181;
    public static inline var kp_leftparen : Int       = 182;
    public static inline var kp_rightparen : Int      = 183;
    public static inline var kp_leftbrace : Int       = 184;
    public static inline var kp_rightbrace : Int      = 185;
    public static inline var kp_tab : Int             = 186;
    public static inline var kp_backspace : Int       = 187;
    public static inline var kp_a : Int               = 188;
    public static inline var kp_b : Int               = 189;
    public static inline var kp_c : Int               = 190;
    public static inline var kp_d : Int               = 191;
    public static inline var kp_e : Int               = 192;
    public static inline var kp_f : Int               = 193;
    public static inline var kp_xor : Int             = 194;
    public static inline var kp_power : Int           = 195;
    public static inline var kp_percent : Int         = 196;
    public static inline var kp_less : Int            = 197;
    public static inline var kp_greater : Int         = 198;
    public static inline var kp_ampersand : Int       = 199;
    public static inline var kp_dblampersand : Int    = 200;
    public static inline var kp_verticalbar : Int     = 201;
    public static inline var kp_dblverticalbar : Int  = 202;
    public static inline var kp_colon : Int           = 203;
    public static inline var kp_hash : Int            = 204;
    public static inline var kp_space : Int           = 205;
    public static inline var kp_at : Int              = 206;
    public static inline var kp_exclam : Int          = 207;
    public static inline var kp_memstore : Int        = 208;
    public static inline var kp_memrecall : Int       = 209;
    public static inline var kp_memclear : Int        = 210;
    public static inline var kp_memadd : Int          = 211;
    public static inline var kp_memsubtract : Int     = 212;
    public static inline var kp_memmultiply : Int     = 213;
    public static inline var kp_memdivide : Int       = 214;
    public static inline var kp_plusminus : Int       = 215;
    public static inline var kp_clear : Int           = 216;
    public static inline var kp_clearentry : Int      = 217;
    public static inline var kp_binary : Int          = 218;
    public static inline var kp_octal : Int           = 219;
    public static inline var kp_decimal : Int         = 220;
    public static inline var kp_hexadecimal : Int     = 221;

    public static inline var lctrl : Int              = 224;
    public static inline var lshift : Int             = 225;
        // alt, option
    public static inline var lalt : Int               = 226;
        // windows, command (apple), meta, super
    public static inline var lmeta : Int              = 227;
    public static inline var rctrl : Int              = 228;
    public static inline var rshift : Int             = 229;
        // alt gr, option
    public static inline var ralt : Int               = 230;
        // windows, command (apple), meta, super
    public static inline var rmeta : Int              = 231;

        // Not sure if this is really not covered
        // by any of the above, but since there's a
        // special KMOD_MODE for it I'm adding it here
    public static inline var mode : Int               = 257;

        //
        // Usage page 0x0C
        // These values are mapped from usage page 0x0C (USB consumer page).

    public static inline var audionext : Int          = 258;
    public static inline var audioprev : Int          = 259;
    public static inline var audiostop : Int          = 260;
    public static inline var audioplay : Int          = 261;
    public static inline var audiomute : Int          = 262;
    public static inline var mediaselect : Int        = 263;
    public static inline var www : Int                = 264;
    public static inline var mail : Int               = 265;
    public static inline var calculator : Int         = 266;
    public static inline var computer : Int           = 267;
    public static inline var ac_search : Int          = 268;
    public static inline var ac_home : Int            = 269;
    public static inline var ac_back : Int            = 270;
    public static inline var ac_forward : Int         = 271;
    public static inline var ac_stop : Int            = 272;
    public static inline var ac_refresh : Int         = 273;
    public static inline var ac_bookmarks : Int       = 274;

        // Walther keys
        // These are values that Christian Walther added (for mac keyboard?).

    public static inline var brightnessdown : Int     = 275;
    public static inline var brightnessup : Int       = 276;

        // Display mirroring/dual display switch, video mode switch */
    public static inline var displayswitch : Int      = 277;

    public static inline var kbdillumtoggle : Int     = 278;
    public static inline var kbdillumdown : Int       = 279;
    public static inline var kbdillumup : Int         = 280;
    public static inline var eject : Int              = 281;
    public static inline var sleep : Int              = 282;

    public static inline var app1 : Int               = 283;
    public static inline var app2 : Int               = 284;

    static var scanecodeNames : Array<String> = [
        null, null, null, null,
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '0',
        'Enter',
        'Escape',
        'Backspace',
        'Tab',
        'Space',
        '-',
        '=',
        '[',
        ']',
        '\\',
        '#',
        ';',
        '\'',
        '`',
        ',',
        '.',
        '/',
        'CapsLock',
        'F1',
        'F2',
        'F3',
        'F4',
        'F5',
        'F6',
        'F7',
        'F8',
        'F9',
        'F10',
        'F11',
        'F12',
        'PrintScreen',
        'ScrollLock',
        'Pause',
        'Insert',
        'Home',
        'PageUp',
        'Delete',
        'End',
        'PageDown',
        'Right',
        'Left',
        'Down',
        'Up',
        'Numlock',
        'Keypad /',
        'Keypad *',
        'Keypad -',
        'Keypad +',
        'Keypad Enter',
        'Keypad 1',
        'Keypad 2',
        'Keypad 3',
        'Keypad 4',
        'Keypad 5',
        'Keypad 6',
        'Keypad 7',
        'Keypad 8',
        'Keypad 9',
        'Keypad 0',
        'Keypad .',
        null,
        'Application',
        'Power',
        'Keypad =',
        'F13',
        'F14',
        'F15',
        'F16',
        'F17',
        'F18',
        'F19',
        'F20',
        'F21',
        'F22',
        'F23',
        'F24',
        'Execute',
        'Help',
        'Menu',
        'Select',
        'Stop',
        'Again',
        'Undo',
        'Cut',
        'Copy',
        'Paste',
        'Find',
        'Mute',
        'VolumeUp',
        'VolumeDown',
        null, null, null,
        'Keypad ,',
        'Keypad = (AS400)',
        null, null, null, null, null, null, null, null, null, null, null, null,
        null, null, null, null, null, null,
        'AltErase',
        'SysReq',
        'Cancel',
        'Clear',
        'Prior',
        'Enter',
        'Separator',
        'Out',
        'Oper',
        'Clear / Again',
        'CrSel',
        'ExSel',
        null, null, null, null, null, null, null, null, null, null, null,
        'Keypad 00',
        'Keypad 000',
        'ThousandsSeparator',
        'DecimalSeparator',
        'CurrencyUnit',
        'CurrencySubUnit',
        'Keypad (',
        'Keypad )',
        'Keypad {',
        'Keypad }',
        'Keypad Tab',
        'Keypad Backspace',
        'Keypad A',
        'Keypad B',
        'Keypad C',
        'Keypad D',
        'Keypad E',
        'Keypad F',
        'Keypad XOR',
        'Keypad ^',
        'Keypad %',
        'Keypad <',
        'Keypad >',
        'Keypad &',
        'Keypad &&',
        'Keypad |',
        'Keypad ||',
        'Keypad :',
        'Keypad #',
        'Keypad Space',
        'Keypad @',
        'Keypad !',
        'Keypad MemStore',
        'Keypad MemRecall',
        'Keypad MemClear',
        'Keypad MemAdd',
        'Keypad MemSubtract',
        'Keypad MemMultiply',
        'Keypad MemDivide',
        'Keypad +/-',
        'Keypad Clear',
        'Keypad ClearEntry',
        'Keypad Binary',
        'Keypad Octal',
        'Keypad Decimal',
        'Keypad Hexadecimal',
        null, null,
        'Left Ctrl',
        'Left Shift',
        'Left Alt',
        'Left Meta',
        'Right Ctrl',
        'Right Shift',
        'Right Alt',
        'Right Meta',
        null, null, null, null, null, null, null, null, null, null, null, null,
        null, null, null, null, null, null, null, null, null, null, null, null,
        null,
        'ModeSwitch',
        'AudioNext',
        'AudioPrev',
        'AudioStop',
        'AudioPlay',
        'AudioMute',
        'MediaSelect',
        'WWW',
        'Mail',
        'Calculator',
        'Computer',
        'AC Search',
        'AC Home',
        'AC Back',
        'AC Forward',
        'AC Stop',
        'AC Refresh',
        'AC Bookmarks',
        'BrightnessDown',
        'BrightnessUp',
        'DisplaySwitch',
        'KBDIllumToggle',
        'KBDIllumDown',
        'KBDIllumUp',
        'Eject',
        'Sleep',
    ];
}
