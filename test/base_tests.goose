// The tests of the group base.
namespace base_tests;

import std;
import os;
import encoding from "..";
import common;

const MEGABYTE: i64 = 1000000;

fn test_encode() {
    // The text that the Python library base64 wrote for the word
    // "hello".
    common::check_b32("hello", "NBSWY3DP");
    common::check_b32hex("hello", "D1IMOR3F");
    common::check_hex("hello", "68656C6C6F");

    // The lower case of the hex.
    var lower: u8[>..] = [];
    let low = encoding::strict_options();
    low.lower = true;
    encoding::hex_encode(lower, "hello", low);
    assert(lower == "68656c6c6f");

    // The lower case of the base32.
    var lower32: u8[>..] = [];
    encoding::base32_encode(lower32, "hello", low);
    assert(lower32 == "nbswy3dp");

    // The empty input holds no byte.
    var a: u8[>..] = [];
    encoding::base32_encode(a, "", encoding::strict_options());
    assert(a.len == 0);
    var b: u8[>..] = [];
    encoding::base32hex_encode(b, "", encoding::strict_options());
    assert(b.len == 0);
    var c: u8[>..] = [];
    encoding::hex_encode(c, "", encoding::strict_options());
    assert(c.len == 0);

    // The tails of every length.
    common::check_b32("A", "IE======");
    common::check_b32("AB", "IFBA====");
    common::check_b32("ABC", "IFBEG===");
    common::check_b32("ABCD", "IFBEGRA=");
    common::check_b32("ABCDE", "IFBEGRCF");
    common::check_b32("ABCDEF", "IFBEGRCFIY======");
    common::check_b32("ABCDEFG", "IFBEGRCFIZDQ====");
    common::check_b32hex("A", "84======");
    common::check_b32hex("AB", "8510====");
    common::check_b32hex("ABC", "85146===");
    common::check_b32hex("ABCD", "85146H0=");
    common::check_b32hex("ABCDE", "85146H25");
    common::check_b32hex("ABCDEF", "85146H258O======");
    common::check_b32hex("ABCDEFG", "85146H258P3G====");
    common::check_hex("A", "41");
    common::check_hex("AB", "4142");
    common::check_hex("ABC", "414243");
    common::check_hex("ABCD", "41424344");
    common::check_hex("ABCDE", "4142434445");
    common::check_hex("ABCDEF", "414243444546");
    common::check_hex("ABCDEFG", "41424344454647");

    // The text options write no padding.
    var d: u8[>..] = [];
    encoding::base32_encode(d, "A", encoding::text_options());
    assert(d == "IE");
    var e: u8[>..] = [];
    encoding::base32_encode(e, "ABCDEFG", encoding::text_options());
    assert(e == "IFBEGRCFIZDQ");
}

fn test_decode() {
    common::check_read("NBSWY3DP", "hello");

    var a: u8[>..] = [];
    let code, pos = encoding::base32hex_decode(a, "D1IMOR3F", encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(a == "hello");

    var b: u8[>..] = [];
    let code2, pos2 = encoding::hex_decode(b, "68656C6C6F", encoding::strict_options());
    assert(code2 == encoding::ERR_OK);
    assert(pos2 == -1);
    assert(b == "hello");

    // The empty text holds no byte.
    var c: u8[>..] = [];
    let code3, pos3 = encoding::base32_decode(c, "", encoding::strict_options());
    assert(code3 == encoding::ERR_OK);
    assert(pos3 == -1);
    assert(c.len == 0);

    // The text with the padding reads back.
    common::check_read("IFBEGRCFIY======", "ABCDEF");
    var d: u8[>..] = [];
    let code4, pos4 = encoding::base32hex_decode(d, "85146H258O======", encoding::strict_options());
    assert(code4 == encoding::ERR_OK);
    assert(d == "ABCDEF");

    // The decoder adds its bytes to the bytes that the buffer holds.
    var e: u8[>..] = [];
    encoding::hex_encode(e, "AA", encoding::strict_options());
    let code5, pos5 = encoding::hex_decode(e, "4142", encoding::strict_options());
    assert(code5 == encoding::ERR_OK);
    assert(e.len == 6);
    assert(e[0] == '4');
    assert(e[1] == '1');
    assert(e[4] == 65);
    assert(e[5] == 66);
}

fn test_round_trip() {
    // Every set of the options comes back as it went out.
    var padding: i64 = 0;
    while padding < 2 {
        var lower: i64 = 0;
        while lower < 2 {
            var space: i64 = 0;
            while space < 2 {
                let opts = encoding::Options { padding: padding == 1,
                                               lower: lower == 1,
                                               skip_space: space == 1, map01: 0,
                                               sep: 0, wrap: 0, adobe: false, exact_case: false };
                var count: i64 = 0;
                while count < 40 {
                    var bytes: u8[>..] = [];
                    bytes.resize(count, 'x');
                    var text: u8[>..] = [];
                    encoding::base32_encode(text, bytes, opts);
                    var back: u8[>..] = [];
                    let code, pos = encoding::base32_decode(back, text, opts);
                    assert(code == encoding::ERR_OK);
                    assert(pos == -1);
                    assert(back == bytes);
                    var text2: u8[>..] = [];
                    encoding::base32hex_encode(text2, bytes, opts);
                    var back2: u8[>..] = [];
                    let code2, pos2 = encoding::base32hex_decode(back2, text2, opts);
                    assert(code2 == encoding::ERR_OK);
                    assert(back2 == bytes);
                    var text3: u8[>..] = [];
                    encoding::hex_encode(text3, bytes, opts);
                    var back3: u8[>..] = [];
                    let code3, pos3 = encoding::hex_decode(back3, text3, opts);
                    assert(code3 == encoding::ERR_OK);
                    assert(back3 == bytes);
                    count = count + 1;
                }
                space = space + 1;
            }
            lower = lower + 1;
        }
        padding = padding + 1;
    }
}

fn test_faults() {
    let strict = encoding::strict_options();
    let plain = encoding::text_options();

    // A byte outside the alphabet.
    var a: u8[>..] = [];
    let code, pos = encoding::base32_decode(a, "NBSWY3D!", strict);
    assert(code == encoding::ERR_INVALID_CHAR);
    assert(pos == 7);
    assert(a.len == 0);

    // A length that no group can hold.
    var b: u8[>..] = [];
    let code2, pos2 = encoding::base32_decode(b, "NBSWY3DPN", strict);
    assert(code2 == encoding::ERR_BAD_LENGTH);
    assert(pos2 == 8);
    var c: u8[>..] = [];
    let code3, pos3 = encoding::base32_decode(c, "NBSWY3DPNNN", strict);
    assert(code3 == encoding::ERR_BAD_LENGTH);
    assert(pos3 == 8);

    // The padding that is required and the text holds none.
    var d: u8[>..] = [];
    let code4, pos4 = encoding::base32_decode(d, "NBSWY3DPEE", strict);
    assert(code4 == encoding::ERR_BAD_PADDING);
    assert(pos4 == 10);

    // The padding that is too long.
    var e: u8[>..] = [];
    let code5, pos5 = encoding::base32_decode(e, "IFBEGRCF====", strict);
    assert(code5 == encoding::ERR_BAD_PADDING);
    assert(pos5 == 8);

    // A byte that stands after the padding.
    var f: u8[>..] = [];
    let code6, pos6 = encoding::base32_decode(f, "NBSWY3DPEE======x", strict);
    assert(code6 == encoding::ERR_BAD_PADDING);
    assert(pos6 == 16);

    // The leftover bits that are not zero.
    var g: u8[>..] = [];
    let code7, pos7 = encoding::base32_decode(g, "NBSWY3DPEF", plain);
    assert(code7 == encoding::ERR_NON_CANONICAL);
    assert(pos7 == 9);
    assert(g.len == 0);

    // The leftover bits of every tail of the base32. The buffer of the
    // caller holds no byte when the text holds leftover bits.
    var tails: i64 = 0;
    while tails < 8 {
        if tails == 0 || tails == 2 || tails == 4 || tails == 5 || tails == 7 {
            var last: i64 = 0;
            while last < 32 {
                let extra = (tails * 5) % 8;
                var want: i64 = encoding::ERR_OK;
                if extra > 0 && (last & ((1 << extra) - 1)) != 0 {
                    want = encoding::ERR_NON_CANONICAL;
                }
                var text: u8[>..] = [];
                text.resize(8 + tails, 'A');
                text[8 + tails - 1] = common::probe_symbol(last);
                var out: u8[>..] = [];
                let code8, pos8 = encoding::base32_decode(out, text, plain);
                assert(code8 == want);
                if want == encoding::ERR_OK {
                    assert(out.len == (8 + tails) * 5 / 8);
                } else {
                    assert(out.len == 0);
                    assert(pos8 == 8 + tails - 1);
                }
                last = last + 1;
            }
        }
        tails = tails + 1;
    }

    // The tail with the leftover bits that are zero reads back.
    var h: u8[>..] = [];
    let code8, pos8 = encoding::base32_decode(h, "NBSWY3DPEE", plain);
    assert(code8 == encoding::ERR_OK);
    assert(h == "hello!");

    // The faults of the hex codec.
    var i: u8[>..] = [];
    let code9, pos9 = encoding::hex_decode(i, "0a0", strict);
    assert(code9 == encoding::ERR_BAD_LENGTH);
    assert(pos9 == 3);
    var j: u8[>..] = [];
    let code10, pos10 = encoding::hex_decode(j, "0a!", strict);
    assert(code10 == encoding::ERR_INVALID_CHAR);
    assert(pos10 == 2);
    var k: u8[>..] = [];
    let code11, pos11 = encoding::hex_decode(k, "0a=0", strict);
    assert(code11 == encoding::ERR_INVALID_CHAR);
    assert(pos11 == 2);

    // With the white space skipped the place is an index of the text.
    var sp: u8[>..] = [];
    let code15, pos15 = encoding::hex_decode(sp, "0a 0b 0", plain);
    assert(code15 == encoding::ERR_BAD_LENGTH);
    assert(pos15 == 7);

    // The fault with the smallest place wins.
    var l: u8[>..] = [];
    let code12, pos12 = encoding::base32_decode(l, "NBSWY3DPNN!", strict);
    assert(code12 == encoding::ERR_BAD_LENGTH);
    assert(pos12 == 8);

    // A byte outside the alphabet wins when the faults stand at the
    // same place.
    var m: u8[>..] = [];
    let code13, pos13 = encoding::base32_decode(m, "NBSWY3DP!", strict);
    assert(code13 == encoding::ERR_INVALID_CHAR);
    assert(pos13 == 8);

    // The buffer of the caller keeps its bytes when the decode fails.
    var n: u8[>..] = [];
    encoding::hex_encode(n, "AA", strict);
    let code14, pos14 = encoding::base32_decode(n, "NBSWY3D!", strict);
    assert(code14 == encoding::ERR_INVALID_CHAR);
    assert(n == "4141");
    assert(n.len == 4);

    // Every fault leaves the buffer of the caller as it was.
    // A byte outside the alphabet.
    var keep: u8[>..] = [];
    encoding::hex_encode(keep, "AA", strict);
    let c1, p1 = encoding::base32_decode(keep, "NBSWY3D!", strict);
    assert(c1 == encoding::ERR_INVALID_CHAR);
    assert(keep == "4141");
    assert(keep.len == 4);

    // A padding that is wrong.
    let t2: u8[>..] = [];
    t2.resize(12, 'F');
    t2[0] = 'I'; t2[1] = 'F'; t2[2] = 'B'; t2[3] = 'E';
    t2[4] = 'G'; t2[5] = 'R'; t2[6] = 'C'; t2[7] = 'F';
    var keep2: u8[>..] = [];
    encoding::hex_encode(keep2, "AA", strict);
    let c2, p2 = encoding::base32_decode(keep2, t2, strict);
    assert(c2 == encoding::ERR_BAD_PADDING);
    assert(keep2 == "4141");
    assert(keep2.len == 4);

    // The leftover bits that are not zero.
    let t3: u8[>..] = [];
    t3.resize(10, 'E');
    t3[0] = 'N'; t3[1] = 'B'; t3[2] = 'S'; t3[3] = 'W';
    t3[4] = 'Y'; t3[5] = '3'; t3[6] = 'D'; t3[7] = 'P';
    t3[8] = 'E'; t3[9] = 'F';
    var keep3: u8[>..] = [];
    encoding::hex_encode(keep3, "AA", strict);
    let c3, p3 = encoding::base32_decode(keep3, t3, plain);
    assert(c3 == encoding::ERR_NON_CANONICAL);
    assert(keep3 == "4141");
    assert(keep3.len == 4);

    // A byte that is not in the alphabet of hex.
    let t4: u8[>..] = [];
    t4.resize(3, '1');
    t4[0] = '4'; t4[1] = '1'; t4[2] = '!';
    var keep4: u8[>..] = [];
    encoding::hex_encode(keep4, "AA", strict);
    let c4, p4 = encoding::hex_decode(keep4, t4, strict);
    assert(c4 == encoding::ERR_INVALID_CHAR);
    assert(keep4 == "4141");
    assert(keep4.len == 4);

    // The same fault in the alphabet of base32hex.
    let t6: u8[>..] = [];
    t6.resize(10, 'A');
    t6[0] = 'D'; t6[1] = '1'; t6[2] = 'I'; t6[3] = 'M';
    t6[4] = 'O'; t6[5] = 'R'; t6[6] = '3'; t6[7] = 'F';
    t6[8] = 'A'; t6[9] = '1';
    var keep5: u8[>..] = [];
    encoding::hex_encode(keep5, "AA", strict);
    let c5, p5 = encoding::base32hex_decode(keep5, t6, plain);
    assert(c5 == encoding::ERR_NON_CANONICAL);
    assert(keep5 == "4141");
    assert(keep5.len == 4);

    // The names of the codes.
    assert(encoding::error_text(encoding::ERR_OK) == "ERR_OK");
    assert(encoding::error_text(encoding::ERR_INVALID_CHAR) == "ERR_INVALID_CHAR");
    assert(encoding::error_text(encoding::ERR_BAD_LENGTH) == "ERR_BAD_LENGTH");
    assert(encoding::error_text(encoding::ERR_BAD_PADDING) == "ERR_BAD_PADDING");
    assert(encoding::error_text(encoding::ERR_NON_CANONICAL) == "ERR_NON_CANONICAL");
    assert(encoding::error_text(99) == "ERR_OK");
}

fn test_options() {
    let strict = encoding::strict_options();
    let plain = encoding::text_options();

    // The text that a person typed.
    var a: u8[>..] = [];
    let code, pos = encoding::base32_decode(a, "nbsw y3dp", plain);
    assert(code == encoding::ERR_OK);
    assert(a == "hello");

    // The strict set refuses the space.
    var b: u8[>..] = [];
    let code2, pos2 = encoding::base32_decode(b, "nbsw y3dp", strict);
    assert(code2 == encoding::ERR_INVALID_CHAR);
    assert(pos2 == 4);

    // The strict set refuses the line break.
    var c: u8[>..] = [];
    let code3, pos3 = encoding::base32_decode(c, "NBSW\nY3DP", strict);
    assert(code3 == encoding::ERR_INVALID_CHAR);
    assert(pos3 == 4);
    var d: u8[>..] = [];
    let code4, pos4 = encoding::base32_decode(d, "NBSW\nY3DP", plain);
    assert(code4 == encoding::ERR_OK);
    assert(d == "hello");

    // The tab and the carriage return.
    var e: u8[>..] = [];
    let code5, pos5 = encoding::base32_decode(e, "NBSW\tY3DP", plain);
    assert(code5 == encoding::ERR_OK);
    assert(e == "hello");
    var f: u8[>..] = [];
    let code6, pos6 = encoding::base32_decode(f, "NBSW\rY3DP", plain);
    assert(code6 == encoding::ERR_OK);
    assert(f == "hello");

    // The text without the padding.
    var g: u8[>..] = [];
    let code7, pos7 = encoding::base32_decode(g, "NBSWY3DPEE", plain);
    assert(code7 == encoding::ERR_OK);
    assert(g == "hello!");

    // The lower case of the letters never changes the bytes.
    var h: u8[>..] = [];
    let code8, pos8 = encoding::hex_decode(h, "68656c6c6f", strict);
    assert(code8 == encoding::ERR_OK);
    assert(h == "hello");
    var i: u8[>..] = [];
    let code9, pos9 = encoding::base32hex_decode(i, "d1imor3f", strict);
    assert(code9 == encoding::ERR_OK);
    assert(i == "hello");

    // The white space of the hex text.
    var j: u8[>..] = [];
    let code10, pos10 = encoding::hex_decode(j, "68 65\n6c 6c 6f", plain);
    assert(code10 == encoding::ERR_OK);
    assert(j == "hello");
}

fn test_hostile() {
    let strict = encoding::strict_options();

    // A text of a megabyte that holds only faults.
    var bad: u8[>..] = [];
    bad.resize(MEGABYTE, '!');
    var out: u8[>..] = [];
    let start = clock();
    let code, pos = encoding::base32_decode(out, bad, strict);
    let elapsed = clock() - start;
    assert(code == encoding::ERR_INVALID_CHAR);
    assert(pos == 0);
    assert(out.len == 0);
    assert(elapsed < 10.0);

    // A megabyte of text that holds only letters.
    var good: u8[>..] = [];
    good.resize(MEGABYTE, 'A');
    var bytes: u8[>..] = [];
    let start2 = clock();
    let code2, pos2 = encoding::base32_decode(bytes, good, strict);
    let elapsed2 = clock() - start2;
    assert(code2 == encoding::ERR_OK);
    assert(bytes.len == MEGABYTE / 8 * 5);

    // A megabyte of bytes encodes and decodes in under one second.
    var raw: u8[>..] = [];
    raw.resize(MEGABYTE, 'z');
    var text: u8[>..] = [];
    let start3 = clock();
    encoding::base32_encode(text, raw, strict);
    var back: u8[>..] = [];
    let code3, pos3 = encoding::base32_decode(back, text, strict);
    let elapsed3 = clock() - start3;
    assert(code3 == encoding::ERR_OK);
    assert(back == raw);
    assert(elapsed3 < 1.0);
    assert(elapsed2 < 5.0);

    // The decoder holds no byte more than the text allows.
    var many: u8[>..] = [];
    many.resize(100000, 'A');
    var small: u8[>..] = [];
    let code4, pos4 = encoding::base32_decode(small, many, strict);
    assert(code4 == encoding::ERR_OK);
    assert(small.len == 100000 / 8 * 5);
}
