// The tests of the group options_more.
namespace options_more_tests;

import std;
import os;
import encoding from "..";
import encoding_checks;

fn test_options_more() {
    let strict = encoding::strict_options();
    let text = encoding::text_options();
    var keep: u8[>..] = [7];

    // The hex separator, as in Python bytes.hex(":").
    var sep = strict;
    sep.sep = ':';
    let hx: u8[3] = [1, 2, 255];
    var o0: u8[>..] = [];
    encoding::hex_encode(o0, hx[..], sep);
    assert(o0 == "01:02:FF");
    var back: u8[>..] = [];
    let c0, p0 = encoding::hex_decode(back, "01:02:FF", sep);
    assert(c0 == encoding::ERR_OK && back == hx[..]);
    let c1, p1 = encoding::hex_decode(keep, "0102:FF", sep);
    assert(c1 == encoding::ERR_INVALID_CHAR && p1 == 2 && keep.len == 1);
    let c2, p2 = encoding::hex_decode(keep, "01:02:", sep);
    assert(c2 == encoding::ERR_INVALID_CHAR && p2 == 5);
    let c3, p3 = encoding::hex_decode(keep, ":0102", sep);
    assert(c3 == encoding::ERR_INVALID_CHAR && p3 == 0);
    let c4, p4 = encoding::hex_decode(keep, "01::02", sep);
    assert(c4 == encoding::ERR_INVALID_CHAR && p4 == 3);
    let c6, p6 = encoding::hex_decode(keep, "01:02", strict);
    assert(c6 == encoding::ERR_INVALID_CHAR && p6 == 2);
    // A hex digit cannot separate, so the separator is off.
    var bad = strict;
    bad.sep = 'a';
    var o1: u8[>..] = [];
    encoding::hex_encode(o1, hx[..], bad);
    assert(o1 == "0102FF");

    // The line width, as in Python a85encode(wrapcol=12).
    var raw: u8[>..] = [];
    var k: i64 = 0;
    while k < 40 { raw.push(k as u8); k = k + 1; }
    var wrap = strict;
    wrap.wrap = 12;
    var o2: u8[>..] = [];
    encoding::ascii85_encode(o2, raw, wrap);
    assert(o2 == "!!*-'\"9eu7#R\nLhG$k3[W&.oN\ng'GVB\"(`=52*\n$$(B+<_pR,UF\ncb");
    var back2: u8[>..] = [];
    let c7, p7 = encoding::ascii85_decode(back2, o2, text);
    assert(c7 == encoding::ERR_OK && back2 == raw);
    // Python a85encode(wrapcol=12, adobe=True): the frame counts in the line.
    var fw = wrap;
    fw.adobe = true;
    var o3: u8[>..] = [];
    encoding::ascii85_encode(o3, raw, fw);
    assert(o3 == "<~!!*-'\"9eu7\n#RLhG$k3[W&.\noNg'GVB\"(`=5\n2*$$(B+<_pR,\nUFcb~>");
    // The end mark never splits. Python gives "<~BOu!rDZ\n~>" for width 10.
    var w10 = encoding_checks::ad_opts(10);
    var o10: u8[>..] = [];
    encoding::ascii85_encode(o10, "hello", w10);
    assert(o10 == "<~BOu!rDZ\n~>");
    var w = 1;
    while w < 14 {
        var ow = encoding_checks::ad_opts(w);
        var oe: u8[>..] = [];
        encoding::ascii85_encode(oe, "hello", ow);
        var td = encoding::text_options();
        td.adobe = true;
        var bk: u8[>..] = [];
        let cw, pw = encoding::ascii85_decode(bk, oe, td);
        assert(cw == encoding::ERR_OK && bk == "hello");
        w = w + 1;
    }
    var o4: u8[>..] = [];
    encoding::base32_encode(o4, raw, wrap);
    assert(o4.len > 32);
    var back3: u8[>..] = [];
    let c8, p8 = encoding::base32_decode(back3, o4, text);
    assert(c8 == encoding::ERR_OK && back3 == raw);
    // A line of exactly the width has no line feed after it.
    var w4 = strict;
    w4.wrap = 4;
    var o5: u8[>..] = [];
    encoding::hex_encode(o5, hx[..], w4);
    assert(o5 == "0102\nFF");
    w4.wrap = 6;
    var o6: u8[>..] = [];
    encoding::hex_encode(o6, hx[..], w4);
    assert(o6 == "0102FF");

    // The frame of Adobe, as in Python a85encode(adobe=True).
    var ad = strict;
    ad.adobe = true;
    var o7: u8[>..] = [];
    encoding::ascii85_encode(o7, "hello", ad);
    assert(o7 == "<~BOu!rDZ~>");
    var back4: u8[>..] = [];
    let c9, p9 = encoding::ascii85_decode(back4, "<~BOu!rDZ~>", ad);
    assert(c9 == encoding::ERR_OK && back4 == "hello");
    let c10, p10 = encoding::ascii85_decode(keep, "BOu!rDZ~>", ad);
    assert(c10 == encoding::ERR_BAD_FRAME && p10 == 0 && keep.len == 1);
    let c11, p11 = encoding::ascii85_decode(keep, "<~BOu!rDZ", ad);
    assert(c11 == encoding::ERR_BAD_FRAME && p11 == 9);
    let c12, p12 = encoding::ascii85_decode(keep, "<~uuuuu~>", ad);
    assert(c12 == encoding::ERR_OVERFLOW && p12 == 2);
    var ad2 = text;
    ad2.adobe = true;
    var back5: u8[>..] = [];
    let c13, p13 = encoding::ascii85_decode(back5, "  <~BOu!\nrDZ~>\n", ad2);
    assert(c13 == encoding::ERR_OK && back5 == "hello");
    var back6: u8[>..] = [];
    let c14, p14 = encoding::ascii85_decode(back6, "<~~>", ad);
    assert(c14 == encoding::ERR_OK && back6.len == 0);
    let c15, p15 = encoding::ascii85_decode(keep, "<~>", ad);
    assert(c15 == encoding::ERR_BAD_FRAME);

    // The exact case, as in Python b32decode(casefold=False).
    var ex = strict;
    ex.exact_case = true;
    var o8: u8[>..] = [];
    let c17, p17 = encoding::base32_decode(o8, "MZXW6YTBOI======", ex);
    assert(c17 == encoding::ERR_OK && o8 == "foobar");
    let c18, p18 = encoding::base32_decode(keep, "mzxw6ytboi======", ex);
    assert(c18 == encoding::ERR_INVALID_CHAR && p18 == 0);
    ex.lower = true;
    var o9: u8[>..] = [];
    let c19, p19 = encoding::base32_decode(o9, "mzxw6ytboi======", ex);
    assert(c19 == encoding::ERR_OK && o9 == "foobar");
    let c20, p20 = encoding::base32_decode(keep, "MZXW6YTBOI======", ex);
    assert(c20 == encoding::ERR_INVALID_CHAR && p20 == 0);
    let c21, p21 = encoding::hex_decode(keep, "0aB4", ex);
    assert(c21 == encoding::ERR_INVALID_CHAR && p21 == 2);
    let c23, p23 = encoding::hex_decode(keep, "0aB4", strict);
    assert(c23 == encoding::ERR_OK);

    // A stream refuses the options that it cannot keep.
    var ws = encoding::encoder_new(encoding::STREAM_HEX, wrap);
    var so: u8[>..] = [];
    let c24, p24 = encoding::stream_write(ws, so, "ab");
    assert(c24 == encoding::ERR_UNSUPPORTED);
}
