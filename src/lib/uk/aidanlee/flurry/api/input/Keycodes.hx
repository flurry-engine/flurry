/**
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014-2015 Sven Bergström http://underscorediscovery.com   
 * Copyright (c) 2014-2015 snow contributors http://github.com/underscorediscovery/snow
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
*/

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
     * @param keycode keycode value
     * @return key name or the letter code value.
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

            case _: Std.string(_keycode);
        }
    }

    public static inline final unknown    = 0;
    public static inline final enter      = 13;
    public static inline final escape     = 27;
    public static inline final backspace  = 8;
    public static inline final tab        = 9;
    public static inline final space      = 32;
    public static inline final exclaim    = 33;
    public static inline final quotedbl   = 34;
    public static inline final hash       = 35;
    public static inline final percent    = 37;
    public static inline final dollar     = 36;
    public static inline final ampersand  = 38;
    public static inline final quote      = 39;
    public static inline final leftparen  = 40;
    public static inline final rightparen = 41;
    public static inline final asterisk   = 42;
    public static inline final plus       = 43;
    public static inline final comma      = 44;
    public static inline final minus      = 45;
    public static inline final period     = 46;
    public static inline final slash      = 47;
    public static inline final key_0      = 48;
    public static inline final key_1      = 49;
    public static inline final key_2      = 50;
    public static inline final key_3      = 51;
    public static inline final key_4      = 52;
    public static inline final key_5      = 53;
    public static inline final key_6      = 54;
    public static inline final key_7      = 55;
    public static inline final key_8      = 56;
    public static inline final key_9      = 57;
    public static inline final colon      = 58;
    public static inline final semicolon  = 59;
    public static inline final less       = 60;
    public static inline final equals     = 61;
    public static inline final greater    = 62;
    public static inline final question   = 63;
    public static inline final at         = 64;

    // Skip uppercase letters

    public static inline final leftbracket  = 91;
    public static inline final backslash    = 92;
    public static inline final rightbracket = 93;
    public static inline final caret        = 94;
    public static inline final underscore   = 95;
    public static inline final backquote    = 96;
    public static inline final key_a        = 97;
    public static inline final key_b        = 98;
    public static inline final key_c        = 99;
    public static inline final key_d        = 100;
    public static inline final key_e        = 101;
    public static inline final key_f        = 102;
    public static inline final key_g        = 103;
    public static inline final key_h        = 104;
    public static inline final key_i        = 105;
    public static inline final key_j        = 106;
    public static inline final key_k        = 107;
    public static inline final key_l        = 108;
    public static inline final key_m        = 109;
    public static inline final key_n        = 110;
    public static inline final key_o        = 111;
    public static inline final key_p        = 112;
    public static inline final key_q        = 113;
    public static inline final key_r        = 114;
    public static inline final key_s        = 115;
    public static inline final key_t        = 116;
    public static inline final key_u        = 117;
    public static inline final key_v        = 118;
    public static inline final key_w        = 119;
    public static inline final key_x        = 120;
    public static inline final key_y        = 121;
    public static inline final key_z        = 122;

    public static final capslock            = fromScan(Scancodes.capslock);
    public static final f1                  = fromScan(Scancodes.f1);
    public static final f2                  = fromScan(Scancodes.f2);
    public static final f3                  = fromScan(Scancodes.f3);
    public static final f4                  = fromScan(Scancodes.f4);
    public static final f5                  = fromScan(Scancodes.f5);
    public static final f6                  = fromScan(Scancodes.f6);
    public static final f7                  = fromScan(Scancodes.f7);
    public static final f8                  = fromScan(Scancodes.f8);
    public static final f9                  = fromScan(Scancodes.f9);
    public static final f10                 = fromScan(Scancodes.f10);
    public static final f11                 = fromScan(Scancodes.f11);
    public static final f12                 = fromScan(Scancodes.f12);
    public static final printscreen         = fromScan(Scancodes.printscreen);
    public static final scrolllock          = fromScan(Scancodes.scrolllock);
    public static final pause               = fromScan(Scancodes.pause);
    public static final insert              = fromScan(Scancodes.insert);
    public static final home                = fromScan(Scancodes.home);
    public static final pageup              = fromScan(Scancodes.pageup);
    public static final delete              = 127;
    public static final end                 = fromScan(Scancodes.end);
    public static final pagedown            = fromScan(Scancodes.pagedown);
    public static final right               = fromScan(Scancodes.right);
    public static final left                = fromScan(Scancodes.left);
    public static final down                = fromScan(Scancodes.down);
    public static final up                  = fromScan(Scancodes.up);
    public static final numlockclear        = fromScan(Scancodes.numlockclear);
    public static final kp_divide           = fromScan(Scancodes.kp_divide);
    public static final kp_multiply         = fromScan(Scancodes.kp_multiply);
    public static final kp_minus            = fromScan(Scancodes.kp_minus);
    public static final kp_plus             = fromScan(Scancodes.kp_plus);
    public static final kp_enter            = fromScan(Scancodes.kp_enter);
    public static final kp_1                = fromScan(Scancodes.kp_1);
    public static final kp_2                = fromScan(Scancodes.kp_2);
    public static final kp_3                = fromScan(Scancodes.kp_3);
    public static final kp_4                = fromScan(Scancodes.kp_4);
    public static final kp_5                = fromScan(Scancodes.kp_5);
    public static final kp_6                = fromScan(Scancodes.kp_6);
    public static final kp_7                = fromScan(Scancodes.kp_7);
    public static final kp_8                = fromScan(Scancodes.kp_8);
    public static final kp_9                = fromScan(Scancodes.kp_9);
    public static final kp_0                = fromScan(Scancodes.kp_0);
    public static final kp_period           = fromScan(Scancodes.kp_period);
    public static final application         = fromScan(Scancodes.application);
    public static final power               = fromScan(Scancodes.power);
    public static final kp_equals           = fromScan(Scancodes.kp_equals);
    public static final f13                 = fromScan(Scancodes.f13);
    public static final f14                 = fromScan(Scancodes.f14);
    public static final f15                 = fromScan(Scancodes.f15);
    public static final f16                 = fromScan(Scancodes.f16);
    public static final f17                 = fromScan(Scancodes.f17);
    public static final f18                 = fromScan(Scancodes.f18);
    public static final f19                 = fromScan(Scancodes.f19);
    public static final f20                 = fromScan(Scancodes.f20);
    public static final f21                 = fromScan(Scancodes.f21);
    public static final f22                 = fromScan(Scancodes.f22);
    public static final f23                 = fromScan(Scancodes.f23);
    public static final f24                 = fromScan(Scancodes.f24);
    public static final execute             = fromScan(Scancodes.execute);
    public static final help                = fromScan(Scancodes.help);
    public static final menu                = fromScan(Scancodes.menu);
    public static final select              = fromScan(Scancodes.select);
    public static final stop                = fromScan(Scancodes.stop);
    public static final again               = fromScan(Scancodes.again);
    public static final undo                = fromScan(Scancodes.undo);
    public static final cut                 = fromScan(Scancodes.cut);
    public static final copy                = fromScan(Scancodes.copy);
    public static final paste               = fromScan(Scancodes.paste);
    public static final find                = fromScan(Scancodes.find);
    public static final mute                = fromScan(Scancodes.mute);
    public static final volumeup            = fromScan(Scancodes.volumeup);
    public static final volumedown          = fromScan(Scancodes.volumedown);
    public static final kp_comma            = fromScan(Scancodes.kp_comma);
    public static final kp_equalsas400      = fromScan(Scancodes.kp_equalsas400);
    public static final alterase            = fromScan(Scancodes.alterase);
    public static final sysreq              = fromScan(Scancodes.sysreq);
    public static final cancel              = fromScan(Scancodes.cancel);
    public static final clear               = fromScan(Scancodes.clear);
    public static final prior               = fromScan(Scancodes.prior);
    public static final return2             = fromScan(Scancodes.return2);
    public static final separator           = fromScan(Scancodes.separator);
    public static final out                 = fromScan(Scancodes.out);
    public static final oper                = fromScan(Scancodes.oper);
    public static final clearagain          = fromScan(Scancodes.clearagain);
    public static final crsel               = fromScan(Scancodes.crsel);
    public static final exsel               = fromScan(Scancodes.exsel);
    public static final kp_00               = fromScan(Scancodes.kp_00);
    public static final kp_000              = fromScan(Scancodes.kp_000);
    public static final thousandsseparator  = fromScan(Scancodes.thousandsseparator);
    public static final decimalseparator    = fromScan(Scancodes.decimalseparator);
    public static final currencyunit        = fromScan(Scancodes.currencyunit);
    public static final currencysubunit     = fromScan(Scancodes.currencysubunit);
    public static final kp_leftparen        = fromScan(Scancodes.kp_leftparen);
    public static final kp_rightparen       = fromScan(Scancodes.kp_rightparen);
    public static final kp_leftbrace        = fromScan(Scancodes.kp_leftbrace);
    public static final kp_rightbrace       = fromScan(Scancodes.kp_rightbrace);
    public static final kp_tab              = fromScan(Scancodes.kp_tab);
    public static final kp_backspace        = fromScan(Scancodes.kp_backspace);
    public static final kp_a                = fromScan(Scancodes.kp_a);
    public static final kp_b                = fromScan(Scancodes.kp_b);
    public static final kp_c                = fromScan(Scancodes.kp_c);
    public static final kp_d                = fromScan(Scancodes.kp_d);
    public static final kp_e                = fromScan(Scancodes.kp_e);
    public static final kp_f                = fromScan(Scancodes.kp_f);
    public static final kp_xor              = fromScan(Scancodes.kp_xor);
    public static final kp_power            = fromScan(Scancodes.kp_power);
    public static final kp_percent          = fromScan(Scancodes.kp_percent);
    public static final kp_less             = fromScan(Scancodes.kp_less);
    public static final kp_greater          = fromScan(Scancodes.kp_greater);
    public static final kp_ampersand        = fromScan(Scancodes.kp_ampersand);
    public static final kp_dblampersand     = fromScan(Scancodes.kp_dblampersand);
    public static final kp_verticalbar      = fromScan(Scancodes.kp_verticalbar);
    public static final kp_dblverticalbar   = fromScan(Scancodes.kp_dblverticalbar);
    public static final kp_colon            = fromScan(Scancodes.kp_colon);
    public static final kp_hash             = fromScan(Scancodes.kp_hash);
    public static final kp_space            = fromScan(Scancodes.kp_space);
    public static final kp_at               = fromScan(Scancodes.kp_at);
    public static final kp_exclam           = fromScan(Scancodes.kp_exclam);
    public static final kp_memstore         = fromScan(Scancodes.kp_memstore);
    public static final kp_memrecall        = fromScan(Scancodes.kp_memrecall);
    public static final kp_memclear         = fromScan(Scancodes.kp_memclear);
    public static final kp_memadd           = fromScan(Scancodes.kp_memadd);
    public static final kp_memsubtract      = fromScan(Scancodes.kp_memsubtract);
    public static final kp_memmultiply      = fromScan(Scancodes.kp_memmultiply);
    public static final kp_memdivide        = fromScan(Scancodes.kp_memdivide);
    public static final kp_plusminus        = fromScan(Scancodes.kp_plusminus);
    public static final kp_clear            = fromScan(Scancodes.kp_clear);
    public static final kp_clearentry       = fromScan(Scancodes.kp_clearentry);
    public static final kp_binary           = fromScan(Scancodes.kp_binary);
    public static final kp_octal            = fromScan(Scancodes.kp_octal);
    public static final kp_decimal          = fromScan(Scancodes.kp_decimal);
    public static final kp_hexadecimal      = fromScan(Scancodes.kp_hexadecimal);
    public static final lctrl               = fromScan(Scancodes.lctrl);
    public static final lshift              = fromScan(Scancodes.lshift);
    public static final lalt                = fromScan(Scancodes.lalt);
    public static final lmeta               = fromScan(Scancodes.lmeta);
    public static final rctrl               = fromScan(Scancodes.rctrl);
    public static final rshift              = fromScan(Scancodes.rshift);
    public static final ralt                = fromScan(Scancodes.ralt);
    public static final rmeta               = fromScan(Scancodes.rmeta);
    public static final mode                = fromScan(Scancodes.mode);
    public static final audionext           = fromScan(Scancodes.audionext);
    public static final audioprev           = fromScan(Scancodes.audioprev);
    public static final audiostop           = fromScan(Scancodes.audiostop);
    public static final audioplay           = fromScan(Scancodes.audioplay);
    public static final audiomute           = fromScan(Scancodes.audiomute);
    public static final mediaselect         = fromScan(Scancodes.mediaselect);
    public static final www                 = fromScan(Scancodes.www);
    public static final mail                = fromScan(Scancodes.mail);
    public static final calculator          = fromScan(Scancodes.calculator);
    public static final computer            = fromScan(Scancodes.computer);
    public static final ac_search           = fromScan(Scancodes.ac_search);
    public static final ac_home             = fromScan(Scancodes.ac_home);
    public static final ac_back             = fromScan(Scancodes.ac_back);
    public static final ac_forward          = fromScan(Scancodes.ac_forward);
    public static final ac_stop             = fromScan(Scancodes.ac_stop);
    public static final ac_refresh          = fromScan(Scancodes.ac_refresh);
    public static final ac_bookmarks        = fromScan(Scancodes.ac_bookmarks);
    public static final brightnessdown      = fromScan(Scancodes.brightnessdown);
    public static final brightnessup        = fromScan(Scancodes.brightnessup);
    public static final displayswitch       = fromScan(Scancodes.displayswitch);
    public static final kbdillumtoggle      = fromScan(Scancodes.kbdillumtoggle);
    public static final kbdillumdown        = fromScan(Scancodes.kbdillumdown);
    public static final kbdillumup          = fromScan(Scancodes.kbdillumup);
    public static final eject               = fromScan(Scancodes.eject);
    public static final sleep               = fromScan(Scancodes.sleep);
}
