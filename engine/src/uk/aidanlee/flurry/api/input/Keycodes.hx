package uk.aidanlee.flurry.api.input;

/**
 * The keycode class, with conversion helpers for scancodes.
 * The values below come directly from SDL header include files, but they aren't specific to SDL so they are used generically.
 */
class Keycodes
{
    /** Convert a scancode to a keycode for comparison */
    public static inline function fromScan(_scancode : Int) : Int
    {
        return (_scancode | Scancodes.MASK);
    }

    /**
     * Convert a keycode to a scancode if possible.
     * NOTE - this will only map a large % but not all keys, there is a list of unmapped keys commented in the code.
     * @param _keycode keycode to convert.
     * @return scancode number
     */
    public static function toScan(_keycode : Int) : Int
    {
            //quite a lot map directly to a masked scancode
            //if that's the case, return it directly
        if ((_keycode & Scancodes.MASK) != 0)
        {
            return _keycode &~ Scancodes.MASK;
        }

            //now we translate them to the scan where unmapped

        return switch (_keycode)
        {
            case Keycodes.enter:         Scancodes.enter;
            case Keycodes.escape:        Scancodes.escape;
            case Keycodes.backspace:     Scancodes.backspace;
            case Keycodes.tab:           Scancodes.tab;
            case Keycodes.space:         Scancodes.space;
            case Keycodes.slash:         Scancodes.slash;
            case Keycodes.key_0:         Scancodes.key_0;
            case Keycodes.key_1:         Scancodes.key_1;
            case Keycodes.key_2:         Scancodes.key_2;
            case Keycodes.key_3:         Scancodes.key_3;
            case Keycodes.key_4:         Scancodes.key_4;
            case Keycodes.key_5:         Scancodes.key_5;
            case Keycodes.key_6:         Scancodes.key_6;
            case Keycodes.key_7:         Scancodes.key_7;
            case Keycodes.key_8:         Scancodes.key_8;
            case Keycodes.key_9:         Scancodes.key_9;
            case Keycodes.semicolon:     Scancodes.semicolon;
            case Keycodes.equals:        Scancodes.equals;
            case Keycodes.leftbracket:   Scancodes.leftbracket;
            case Keycodes.backslash:     Scancodes.backslash;
            case Keycodes.rightbracket:  Scancodes.rightbracket;
            case Keycodes.backquote:     Scancodes.grave;
            case Keycodes.key_a:         Scancodes.key_a;
            case Keycodes.key_b:         Scancodes.key_b;
            case Keycodes.key_c:         Scancodes.key_c;
            case Keycodes.key_d:         Scancodes.key_d;
            case Keycodes.key_e:         Scancodes.key_e;
            case Keycodes.key_f:         Scancodes.key_f;
            case Keycodes.key_g:         Scancodes.key_g;
            case Keycodes.key_h:         Scancodes.key_h;
            case Keycodes.key_i:         Scancodes.key_i;
            case Keycodes.key_j:         Scancodes.key_j;
            case Keycodes.key_k:         Scancodes.key_k;
            case Keycodes.key_l:         Scancodes.key_l;
            case Keycodes.key_m:         Scancodes.key_m;
            case Keycodes.key_n:         Scancodes.key_n;
            case Keycodes.key_o:         Scancodes.key_o;
            case Keycodes.key_p:         Scancodes.key_p;
            case Keycodes.key_q:         Scancodes.key_q;
            case Keycodes.key_r:         Scancodes.key_r;
            case Keycodes.key_s:         Scancodes.key_s;
            case Keycodes.key_t:         Scancodes.key_t;
            case Keycodes.key_u:         Scancodes.key_u;
            case Keycodes.key_v:         Scancodes.key_v;
            case Keycodes.key_w:         Scancodes.key_w;
            case Keycodes.key_x:         Scancodes.key_x;
            case Keycodes.key_y:         Scancodes.key_y;
            case Keycodes.key_z:         Scancodes.key_z;
            default: Scancodes.unknown;


                //These are unmappable because they are not keys
                //but values on the key (like a shift key combo)
                //and to hardcode them to the key you think it is,
                //would be to map it to a fixed locale probably.
                //They don't have scancodes, so we don't return one
            // case exclaim:      ;
            // case quotedbl:     ;
            // case hash:         ;
            // case percent:      ;
            // case dollar:       ;
            // case ampersand:    ;
            // case quote:        ;
            // case leftparen:    ;
            // case rightparen:   ;
            // case asterisk:     ;
            // case plus:         ;
            // case comma:        ;
            // case minus:        ;
            // case period:       ;
            // case less:         ;
            // case colon:        ;
            // case greater:      ;
            // case question:     ;
            // case at:           ;
            // case caret:        ;
            // case underscore:   ;
        }
    }

    /**
     * Convert a keycode to a string
     * @param keycode 
     * @return String name
     */
    public static function name(_keycode : Int) : String
    {
        //we don't use to_scan because it would consume
        //the typeable characters and we want those as unicode etc.

        if ((_keycode & Scancodes.MASK) != 0)
        {
            return Scancodes.name(_keycode &~ Scancodes.MASK);
        }

        return switch (_keycode)
        {
            case Keycodes.enter:     Scancodes.name(Scancodes.enter);
            case Keycodes.escape:    Scancodes.name(Scancodes.escape);
            case Keycodes.backspace: Scancodes.name(Scancodes.backspace);
            case Keycodes.tab:       Scancodes.name(Scancodes.tab);
            case Keycodes.space:     Scancodes.name(Scancodes.space);
            case Keycodes.delete:    Scancodes.name(Scancodes.delete);

            default :
                var decoder = new haxe.Utf8();
                decoder.addChar(_keycode);
                
                return decoder.toString();
        }
    }

    public static inline final unknown : Int              = 0;

    public static inline final enter : Int                = 13;
    public static inline final escape : Int               = 27;
    public static inline final backspace : Int            = 8;
    public static inline final tab : Int                  = 9;
    public static inline final space : Int                = 32;
    public static inline final exclaim : Int              = 33;
    public static inline final quotedbl : Int             = 34;
    public static inline final hash : Int                 = 35;
    public static inline final percent : Int              = 37;
    public static inline final dollar : Int               = 36;
    public static inline final ampersand : Int            = 38;
    public static inline final quote : Int                = 39;
    public static inline final leftparen : Int            = 40;
    public static inline final rightparen : Int           = 41;
    public static inline final asterisk : Int             = 42;
    public static inline final plus : Int                 = 43;
    public static inline final comma : Int                = 44;
    public static inline final minus : Int                = 45;
    public static inline final period : Int               = 46;
    public static inline final slash : Int                = 47;
    public static inline final key_0 : Int                = 48;
    public static inline final key_1 : Int                = 49;
    public static inline final key_2 : Int                = 50;
    public static inline final key_3 : Int                = 51;
    public static inline final key_4 : Int                = 52;
    public static inline final key_5 : Int                = 53;
    public static inline final key_6 : Int                = 54;
    public static inline final key_7 : Int                = 55;
    public static inline final key_8 : Int                = 56;
    public static inline final key_9 : Int                = 57;
    public static inline final colon : Int                = 58;
    public static inline final semicolon : Int            = 59;
    public static inline final less : Int                 = 60;
    public static inline final equals : Int               = 61;
    public static inline final greater : Int              = 62;
    public static inline final question : Int             = 63;
    public static inline final at : Int                   = 64;

       // Skip uppercase letters

    public static inline final leftbracket : Int          = 91;
    public static inline final backslash : Int            = 92;
    public static inline final rightbracket : Int         = 93;
    public static inline final caret : Int                = 94;
    public static inline final underscore : Int           = 95;
    public static inline final backquote : Int            = 96;
    public static inline final key_a : Int                = 97;
    public static inline final key_b : Int                = 98;
    public static inline final key_c : Int                = 99;
    public static inline final key_d : Int                = 100;
    public static inline final key_e : Int                = 101;
    public static inline final key_f : Int                = 102;
    public static inline final key_g : Int                = 103;
    public static inline final key_h : Int                = 104;
    public static inline final key_i : Int                = 105;
    public static inline final key_j : Int                = 106;
    public static inline final key_k : Int                = 107;
    public static inline final key_l : Int                = 108;
    public static inline final key_m : Int                = 109;
    public static inline final key_n : Int                = 110;
    public static inline final key_o : Int                = 111;
    public static inline final key_p : Int                = 112;
    public static inline final key_q : Int                = 113;
    public static inline final key_r : Int                = 114;
    public static inline final key_s : Int                = 115;
    public static inline final key_t : Int                = 116;
    public static inline final key_u : Int                = 117;
    public static inline final key_v : Int                = 118;
    public static inline final key_w : Int                = 119;
    public static inline final key_x : Int                = 120;
    public static inline final key_y : Int                = 121;
    public static inline final key_z : Int                = 122;

    public static final capslock : Int             = fromScan(Scancodes.capslock);

    public static final f1 : Int                   = fromScan(Scancodes.f1);
    public static final f2 : Int                   = fromScan(Scancodes.f2);
    public static final f3 : Int                   = fromScan(Scancodes.f3);
    public static final f4 : Int                   = fromScan(Scancodes.f4);
    public static final f5 : Int                   = fromScan(Scancodes.f5);
    public static final f6 : Int                   = fromScan(Scancodes.f6);
    public static final f7 : Int                   = fromScan(Scancodes.f7);
    public static final f8 : Int                   = fromScan(Scancodes.f8);
    public static final f9 : Int                   = fromScan(Scancodes.f9);
    public static final f10 : Int                  = fromScan(Scancodes.f10);
    public static final f11 : Int                  = fromScan(Scancodes.f11);
    public static final f12 : Int                  = fromScan(Scancodes.f12);

    public static final printscreen : Int          = fromScan(Scancodes.printscreen);
    public static final scrolllock : Int           = fromScan(Scancodes.scrolllock);
    public static final pause : Int                = fromScan(Scancodes.pause);
    public static final insert : Int               = fromScan(Scancodes.insert);
    public static final home : Int                 = fromScan(Scancodes.home);
    public static final pageup : Int               = fromScan(Scancodes.pageup);
    public static final delete : Int               = 127;
    public static final end : Int                  = fromScan(Scancodes.end);
    public static final pagedown : Int             = fromScan(Scancodes.pagedown);
    public static final right : Int                = fromScan(Scancodes.right);
    public static final left : Int                 = fromScan(Scancodes.left);
    public static final down : Int                 = fromScan(Scancodes.down);
    public static final up : Int                   = fromScan(Scancodes.up);

    public static final numlockclear : Int         = fromScan(Scancodes.numlockclear);
    public static final kp_divide : Int            = fromScan(Scancodes.kp_divide);
    public static final kp_multiply : Int          = fromScan(Scancodes.kp_multiply);
    public static final kp_minus : Int             = fromScan(Scancodes.kp_minus);
    public static final kp_plus : Int              = fromScan(Scancodes.kp_plus);
    public static final kp_enter : Int             = fromScan(Scancodes.kp_enter);
    public static final kp_1 : Int                 = fromScan(Scancodes.kp_1);
    public static final kp_2 : Int                 = fromScan(Scancodes.kp_2);
    public static final kp_3 : Int                 = fromScan(Scancodes.kp_3);
    public static final kp_4 : Int                 = fromScan(Scancodes.kp_4);
    public static final kp_5 : Int                 = fromScan(Scancodes.kp_5);
    public static final kp_6 : Int                 = fromScan(Scancodes.kp_6);
    public static final kp_7 : Int                 = fromScan(Scancodes.kp_7);
    public static final kp_8 : Int                 = fromScan(Scancodes.kp_8);
    public static final kp_9 : Int                 = fromScan(Scancodes.kp_9);
    public static final kp_0 : Int                 = fromScan(Scancodes.kp_0);
    public static final kp_period : Int            = fromScan(Scancodes.kp_period);

    public static final application : Int          = fromScan(Scancodes.application);
    public static final power : Int                = fromScan(Scancodes.power);
    public static final kp_equals : Int            = fromScan(Scancodes.kp_equals);
    public static final f13 : Int                  = fromScan(Scancodes.f13);
    public static final f14 : Int                  = fromScan(Scancodes.f14);
    public static final f15 : Int                  = fromScan(Scancodes.f15);
    public static final f16 : Int                  = fromScan(Scancodes.f16);
    public static final f17 : Int                  = fromScan(Scancodes.f17);
    public static final f18 : Int                  = fromScan(Scancodes.f18);
    public static final f19 : Int                  = fromScan(Scancodes.f19);
    public static final f20 : Int                  = fromScan(Scancodes.f20);
    public static final f21 : Int                  = fromScan(Scancodes.f21);
    public static final f22 : Int                  = fromScan(Scancodes.f22);
    public static final f23 : Int                  = fromScan(Scancodes.f23);
    public static final f24 : Int                  = fromScan(Scancodes.f24);
    public static final execute : Int              = fromScan(Scancodes.execute);
    public static final help : Int                 = fromScan(Scancodes.help);
    public static final menu : Int                 = fromScan(Scancodes.menu);
    public static final select : Int               = fromScan(Scancodes.select);
    public static final stop : Int                 = fromScan(Scancodes.stop);
    public static final again : Int                = fromScan(Scancodes.again);
    public static final undo : Int                 = fromScan(Scancodes.undo);
    public static final cut : Int                  = fromScan(Scancodes.cut);
    public static final copy : Int                 = fromScan(Scancodes.copy);
    public static final paste : Int                = fromScan(Scancodes.paste);
    public static final find : Int                 = fromScan(Scancodes.find);
    public static final mute : Int                 = fromScan(Scancodes.mute);
    public static final volumeup : Int             = fromScan(Scancodes.volumeup);
    public static final volumedown : Int           = fromScan(Scancodes.volumedown);
    public static final kp_comma : Int             = fromScan(Scancodes.kp_comma);
    public static final kp_equalsas400 : Int       = fromScan(Scancodes.kp_equalsas400);

    public static final alterase : Int             = fromScan(Scancodes.alterase);
    public static final sysreq : Int               = fromScan(Scancodes.sysreq);
    public static final cancel : Int               = fromScan(Scancodes.cancel);
    public static final clear : Int                = fromScan(Scancodes.clear);
    public static final prior : Int                = fromScan(Scancodes.prior);
    public static final return2 : Int              = fromScan(Scancodes.return2);
    public static final separator : Int            = fromScan(Scancodes.separator);
    public static final out : Int                  = fromScan(Scancodes.out);
    public static final oper : Int                 = fromScan(Scancodes.oper);
    public static final clearagain : Int           = fromScan(Scancodes.clearagain);
    public static final crsel : Int                = fromScan(Scancodes.crsel);
    public static final exsel : Int                = fromScan(Scancodes.exsel);

    public static final kp_00 : Int                = fromScan(Scancodes.kp_00);
    public static final kp_000 : Int               = fromScan(Scancodes.kp_000);
    public static final thousandsseparator : Int   = fromScan(Scancodes.thousandsseparator);
    public static final decimalseparator : Int     = fromScan(Scancodes.decimalseparator);
    public static final currencyunit : Int         = fromScan(Scancodes.currencyunit);
    public static final currencysubunit : Int      = fromScan(Scancodes.currencysubunit);
    public static final kp_leftparen : Int         = fromScan(Scancodes.kp_leftparen);
    public static final kp_rightparen : Int        = fromScan(Scancodes.kp_rightparen);
    public static final kp_leftbrace : Int         = fromScan(Scancodes.kp_leftbrace);
    public static final kp_rightbrace : Int        = fromScan(Scancodes.kp_rightbrace);
    public static final kp_tab : Int               = fromScan(Scancodes.kp_tab);
    public static final kp_backspace : Int         = fromScan(Scancodes.kp_backspace);
    public static final kp_a : Int                 = fromScan(Scancodes.kp_a);
    public static final kp_b : Int                 = fromScan(Scancodes.kp_b);
    public static final kp_c : Int                 = fromScan(Scancodes.kp_c);
    public static final kp_d : Int                 = fromScan(Scancodes.kp_d);
    public static final kp_e : Int                 = fromScan(Scancodes.kp_e);
    public static final kp_f : Int                 = fromScan(Scancodes.kp_f);
    public static final kp_xor : Int               = fromScan(Scancodes.kp_xor);
    public static final kp_power : Int             = fromScan(Scancodes.kp_power);
    public static final kp_percent : Int           = fromScan(Scancodes.kp_percent);
    public static final kp_less : Int              = fromScan(Scancodes.kp_less);
    public static final kp_greater : Int           = fromScan(Scancodes.kp_greater);
    public static final kp_ampersand : Int         = fromScan(Scancodes.kp_ampersand);
    public static final kp_dblampersand : Int      = fromScan(Scancodes.kp_dblampersand);
    public static final kp_verticalbar : Int       = fromScan(Scancodes.kp_verticalbar);
    public static final kp_dblverticalbar : Int    = fromScan(Scancodes.kp_dblverticalbar);
    public static final kp_colon : Int             = fromScan(Scancodes.kp_colon);
    public static final kp_hash : Int              = fromScan(Scancodes.kp_hash);
    public static final kp_space : Int             = fromScan(Scancodes.kp_space);
    public static final kp_at : Int                = fromScan(Scancodes.kp_at);
    public static final kp_exclam : Int            = fromScan(Scancodes.kp_exclam);
    public static final kp_memstore : Int          = fromScan(Scancodes.kp_memstore);
    public static final kp_memrecall : Int         = fromScan(Scancodes.kp_memrecall);
    public static final kp_memclear : Int          = fromScan(Scancodes.kp_memclear);
    public static final kp_memadd : Int            = fromScan(Scancodes.kp_memadd);
    public static final kp_memsubtract : Int       = fromScan(Scancodes.kp_memsubtract);
    public static final kp_memmultiply : Int       = fromScan(Scancodes.kp_memmultiply);
    public static final kp_memdivide : Int         = fromScan(Scancodes.kp_memdivide);
    public static final kp_plusminus : Int         = fromScan(Scancodes.kp_plusminus);
    public static final kp_clear : Int             = fromScan(Scancodes.kp_clear);
    public static final kp_clearentry : Int        = fromScan(Scancodes.kp_clearentry);
    public static final kp_binary : Int            = fromScan(Scancodes.kp_binary);
    public static final kp_octal : Int             = fromScan(Scancodes.kp_octal);
    public static final kp_decimal : Int           = fromScan(Scancodes.kp_decimal);
    public static final kp_hexadecimal : Int       = fromScan(Scancodes.kp_hexadecimal);

    public static final lctrl : Int                = fromScan(Scancodes.lctrl);
    public static final lshift : Int               = fromScan(Scancodes.lshift);
    public static final lalt : Int                 = fromScan(Scancodes.lalt);
    public static final lmeta : Int                = fromScan(Scancodes.lmeta);
    public static final rctrl : Int                = fromScan(Scancodes.rctrl);
    public static final rshift : Int               = fromScan(Scancodes.rshift);
    public static final ralt : Int                 = fromScan(Scancodes.ralt);
    public static final rmeta : Int                = fromScan(Scancodes.rmeta);

    public static final mode : Int                 = fromScan(Scancodes.mode);

    public static final audionext : Int            = fromScan(Scancodes.audionext);
    public static final audioprev : Int            = fromScan(Scancodes.audioprev);
    public static final audiostop : Int            = fromScan(Scancodes.audiostop);
    public static final audioplay : Int            = fromScan(Scancodes.audioplay);
    public static final audiomute : Int            = fromScan(Scancodes.audiomute);
    public static final mediaselect : Int          = fromScan(Scancodes.mediaselect);
    public static final www : Int                  = fromScan(Scancodes.www);
    public static final mail : Int                 = fromScan(Scancodes.mail);
    public static final calculator : Int           = fromScan(Scancodes.calculator);
    public static final computer : Int             = fromScan(Scancodes.computer);
    public static final ac_search : Int            = fromScan(Scancodes.ac_search);
    public static final ac_home : Int              = fromScan(Scancodes.ac_home);
    public static final ac_back : Int              = fromScan(Scancodes.ac_back);
    public static final ac_forward : Int           = fromScan(Scancodes.ac_forward);
    public static final ac_stop : Int              = fromScan(Scancodes.ac_stop);
    public static final ac_refresh : Int           = fromScan(Scancodes.ac_refresh);
    public static final ac_bookmarks : Int         = fromScan(Scancodes.ac_bookmarks);

    public static final brightnessdown : Int       = fromScan(Scancodes.brightnessdown);
    public static final brightnessup : Int         = fromScan(Scancodes.brightnessup);
    public static final displayswitch : Int        = fromScan(Scancodes.displayswitch);
    public static final kbdillumtoggle : Int       = fromScan(Scancodes.kbdillumtoggle);
    public static final kbdillumdown : Int         = fromScan(Scancodes.kbdillumdown);
    public static final kbdillumup : Int           = fromScan(Scancodes.kbdillumup);
    public static final eject : Int                = fromScan(Scancodes.eject);
    public static final sleep : Int                = fromScan(Scancodes.sleep);
}
