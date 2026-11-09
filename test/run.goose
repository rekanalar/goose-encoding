// Tests for the encoding package. Run with: goose run test/run.goose
//
// The tests hold the text that the Python library base64 and the Go
// library encoding/base32 and encoding/hex write. They hold the faults
// of the decoders and the place of each fault.

import std;
import os;
import encoding from "..";

// The count of the bytes of a megabyte.
const MEGABYTE: i64 = 1000000;

// check_b32 holds the base32 text of the bytes.
fn check_b32(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::base32_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_b32hex holds the base32hex text of the bytes.
fn check_b32hex(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::base32hex_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_hex holds the hex text of the bytes.
fn check_hex(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::hex_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_a85 holds the ASCII85 text of the bytes.
fn check_a85(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::ascii85_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_b85 holds the base85 text of the bytes.
fn check_b85(src: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    encoding::base85_encode(out, src, encoding::strict_options());
    assert(out == want);
}

// check_read_a85 holds the bytes of the ASCII85 text.
fn check_read_a85(text: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    let code, pos = encoding::ascii85_decode(out, text, encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(out == want);
}

// check_read_b85 holds the bytes of the base85 text.
fn check_read_b85(text: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    let code, pos = encoding::base85_decode(out, text, encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(out == want);
}

// check_read holds the bytes of the base32 text.
fn check_read(text: const u8[:], want: const u8[:]) {
    var out: u8[>..] = [];
    let code, pos = encoding::base32_decode(out, text, encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(out == want);
}

// probe_symbol gives the character of a value of 5 bits in the
// alphabet of base32.
fn probe_symbol(v: i64) -> u8 {
    if v < 26 { return ('A' + v) as u8; }
    return ('2' + (v - 26)) as u8;
}

fn test_encode() {
    // The text that the Python library base64 wrote for the word
    // "hello".
    check_b32("hello", "NBSWY3DP");
    check_b32hex("hello", "D1IMOR3F");
    check_hex("hello", "68656C6C6F");

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
    check_b32("A", "IE======");
    check_b32("AB", "IFBA====");
    check_b32("ABC", "IFBEG===");
    check_b32("ABCD", "IFBEGRA=");
    check_b32("ABCDE", "IFBEGRCF");
    check_b32("ABCDEF", "IFBEGRCFIY======");
    check_b32("ABCDEFG", "IFBEGRCFIZDQ====");
    check_b32hex("A", "84======");
    check_b32hex("AB", "8510====");
    check_b32hex("ABC", "85146===");
    check_b32hex("ABCD", "85146H0=");
    check_b32hex("ABCDE", "85146H25");
    check_b32hex("ABCDEF", "85146H258O======");
    check_b32hex("ABCDEFG", "85146H258P3G====");
    check_hex("A", "41");
    check_hex("AB", "4142");
    check_hex("ABC", "414243");
    check_hex("ABCD", "41424344");
    check_hex("ABCDE", "4142434445");
    check_hex("ABCDEF", "414243444546");
    check_hex("ABCDEFG", "41424344454647");

    // The text options write no padding.
    var d: u8[>..] = [];
    encoding::base32_encode(d, "A", encoding::text_options());
    assert(d == "IE");
    var e: u8[>..] = [];
    encoding::base32_encode(e, "ABCDEFG", encoding::text_options());
    assert(e == "IFBEGRCFIZDQ");
}

fn test_decode() {
    check_read("NBSWY3DP", "hello");

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
    check_read("IFBEGRCFIY======", "ABCDEF");
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
                text[8 + tails - 1] = probe_symbol(last);
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

fn test_encode85() {
    // The empty input holds no byte.
    var empty: u8[>..] = [];
    encoding::ascii85_encode(empty, "", encoding::strict_options());
    assert(empty.len == 0);
    var empty2: u8[>..] = [];
    encoding::base85_encode(empty2, "", encoding::strict_options());
    assert(empty2.len == 0);

    // The text that the Python library base64 wrote.
    check_a85("A", "5l");
    check_a85("AB", "5sb");
    check_a85("ABC", "5sdp");
    check_a85("ABCD", "5sdq,");
    check_a85("hello", "BOu!rDZ");
    check_a85("\x00\x00\x00\x00", "z");
    check_a85("\xff\xff\xff\xff", "s8W-!");
    check_a85("\x00", "!!");
    check_a85("\x00\x00", "!!!");
    check_a85("\x00\x00\x00", "!!!!");
    check_a85("\x01\x02\x03\x04", "!<N?+");

    check_b85("A", "K>");
    check_b85("AB", "K|%");
    check_b85("ABC", "K|(_");
    check_b85("ABCD", "K|(`B");
    check_b85("hello", "Xk~0{Zv");
    check_b85("\x00\x00\x00\x00", "00000");
    check_b85("\xff\xff\xff\xff", "|NsC0");
    check_b85("\x00", "00");
    check_b85("\x00\x00", "000");
    check_b85("\x00\x00\x00", "0000");
    check_b85("\x01\x02\x03\x04", "0RjUA");
}

fn test_decode85() {
    check_read_a85("BOu!rDZ", "hello");
    check_read_a85("z", "\x00\x00\x00\x00");
    check_read_a85("!!!!!", "\x00\x00\x00\x00");
    check_read_a85("Ac", "f");
    check_read_a85("00000", "\x2f\x3a\x02\xa3");
    check_read_a85("zAc", "\x00\x00\x00\x00f");

    // The < of the frame of Adobe is a digit of ASCII85.
    check_read_a85("!<N?+", "\x01\x02\x03\x04");

    check_read_b85("Xk~0{Zv", "hello");
    check_read_b85("00000", "\x00\x00\x00\x00");
    check_read_b85("W&", "f");
    check_read_b85("!!!!!", "\xc3\x34\x0a\xe6");

    // The empty text holds no byte.
    var a: u8[>..] = [];
    let code, pos = encoding::ascii85_decode(a, "", encoding::strict_options());
    assert(code == encoding::ERR_OK);
    assert(pos == -1);
    assert(a.len == 0);

    // The text of only white space holds no byte.
    var b: u8[>..] = [];
    let code2, pos2 = encoding::ascii85_decode(b, "  ", encoding::text_options());
    assert(code2 == encoding::ERR_OK);
    assert(pos2 == -1);
    assert(b.len == 0);
}

fn test_faults85() {
    // A byte outside the alphabet.
    var a: u8[>..] = [];
    let code, pos = encoding::ascii85_decode(a, "BOu!rDZ~", encoding::strict_options());
    assert(code == encoding::ERR_INVALID_CHAR);
    assert(pos == 7);

    // The shortcut z in the middle of a group.
    var b: u8[>..] = [];
    let code2, pos2 = encoding::ascii85_decode(b, "Acz", encoding::strict_options());
    assert(code2 == encoding::ERR_INVALID_CHAR);
    assert(pos2 == 2);

    // The shortcut y of btoa. It is not a part of the Adobe format.
    var c: u8[>..] = [];
    let code3, pos3 = encoding::ascii85_decode(c, "y", encoding::strict_options());
    assert(code3 == encoding::ERR_INVALID_CHAR);
    assert(pos3 == 0);

    // A group that holds more than 32 bits.
    var d: u8[>..] = [];
    let code4, pos4 = encoding::ascii85_decode(d, "uuuuu", encoding::strict_options());
    assert(code4 == encoding::ERR_OVERFLOW);
    assert(pos4 == 0);

    // The same group in the base85 codec.
    var e: u8[>..] = [];
    let code5, pos5 = encoding::base85_decode(e, "~~~~~", encoding::strict_options());
    assert(code5 == encoding::ERR_OVERFLOW);
    assert(pos5 == 0);

    // A tail that holds more than 32 bits.
    var f: u8[>..] = [];
    let code6, pos6 = encoding::ascii85_decode(f, "uu", encoding::strict_options());
    assert(code6 == encoding::ERR_OVERFLOW);
    assert(pos6 == 0);

    // An overflow in the second group.
    var g: u8[>..] = [];
    let code7, pos7 = encoding::ascii85_decode(g, "BOu!ruuuuu", encoding::strict_options());
    assert(code7 == encoding::ERR_OVERFLOW);
    assert(pos7 == 5);

    // A tail of one character holds no byte.
    var h: u8[>..] = [];
    let code8, pos8 = encoding::ascii85_decode(h, "A", encoding::strict_options());
    assert(code8 == encoding::ERR_BAD_LENGTH);
    assert(pos8 == 0);

    // The same tail in the base85 codec.
    var i: u8[>..] = [];
    let code9, pos9 = encoding::base85_decode(i, "V", encoding::strict_options());
    assert(code9 == encoding::ERR_BAD_LENGTH);
    assert(pos9 == 0);

    // A tail that is not the tail of its own bytes.
    var j: u8[>..] = [];
    let code10, pos10 = encoding::ascii85_decode(j, "Ad", encoding::strict_options());
    assert(code10 == encoding::ERR_NON_CANONICAL);
    assert(pos10 == 1);

    // The same tail in the base85 codec.
    var k: u8[>..] = [];
    let code11, pos11 = encoding::base85_decode(k, "W(", encoding::strict_options());
    assert(code11 == encoding::ERR_NON_CANONICAL);
    assert(pos11 == 1);

    // The fault with the smallest position comes first.
    var l: u8[>..] = [];
    let code12, pos12 = encoding::ascii85_decode(l, "~uuuuu", encoding::strict_options());
    assert(code12 == encoding::ERR_INVALID_CHAR);
    assert(pos12 == 0);

    // The check of the tail runs last. A bad byte comes first.
    var n: u8[>..] = [];
    let code14, pos14 = encoding::ascii85_decode(n, "Ad~", encoding::strict_options());
    assert(code14 == encoding::ERR_INVALID_CHAR);
    assert(pos14 == 2);

    // A fault leaves the buffer of the caller as it was.
    var m: u8[>..] = [];
    m.push(7);
    let code13, pos13 = encoding::ascii85_decode(m, "uuuuu", encoding::strict_options());
    assert(code13 == encoding::ERR_OVERFLOW);
    assert(pos13 == 0);
    assert(m.len == 1);
    assert(m[0] == 7);
}

fn test_options85() {
    // The white space is a fault with the strict options.
    var a: u8[>..] = [];
    let code, pos = encoding::ascii85_decode(a, "BOu! rDZ", encoding::strict_options());
    assert(code == encoding::ERR_INVALID_CHAR);
    assert(pos == 4);

    // The text options skip it.
    var b: u8[>..] = [];
    let code2, pos2 = encoding::ascii85_decode(b, "BOu! rDZ", encoding::text_options());
    assert(code2 == encoding::ERR_OK);
    assert(pos2 == -1);
    assert(b == "hello");

    // The tab and the line feed.
    var c: u8[>..] = [];
    let code3, pos3 = encoding::ascii85_decode(c, "BOu!\trDZ", encoding::text_options());
    assert(code3 == encoding::ERR_OK);
    assert(c == "hello");
    var d: u8[>..] = [];
    let code4, pos4 = encoding::ascii85_decode(d, "BOu!\r\nrDZ", encoding::text_options());
    assert(code4 == encoding::ERR_OK);
    assert(d == "hello");

    // The fields of the padding and the case change nothing.
    var e: u8[>..] = [];
    encoding::ascii85_encode(e, "hello", encoding::strict_options());
    assert(e == "BOu!rDZ");
    var f: u8[>..] = [];
    encoding::base85_encode(f, "hello", encoding::text_options());
    assert(f == "Xk~0{Zv");
}

fn test_round_trip85() {
    // Every length from 0 to 8 and every byte value.
    var n: i64 = 0;
    while n < 9 {
        var src: u8[>..] = [];
        var i: i64 = 0;
        while i < n {
            src.push((i * 37 + 11) as u8);
            i = i + 1;
        }
        var text: u8[>..] = [];
        encoding::ascii85_encode(text, src, encoding::strict_options());
        var back: u8[>..] = [];
        let code, pos = encoding::ascii85_decode(back, text, encoding::strict_options());
        assert(code == encoding::ERR_OK);
        assert(pos == -1);
        assert(back == src);

        var text2: u8[>..] = [];
        encoding::base85_encode(text2, src, encoding::strict_options());
        var back2: u8[>..] = [];
        let code2, pos2 = encoding::base85_decode(back2, text2, encoding::strict_options());
        assert(code2 == encoding::ERR_OK);
        assert(pos2 == -1);
        assert(back2 == src);
        n = n + 1;
    }
}

fn test_hostile85() {
    let strict = encoding::strict_options();

    // A megabyte of text that holds only groups that overflow.
    var bad: u8[>..] = [];
    bad.resize(MEGABYTE, 'u');
    var out: u8[>..] = [];
    let start = clock();
    let code, pos = encoding::ascii85_decode(out, bad, strict);
    let elapsed = clock() - start;
    assert(code == encoding::ERR_OVERFLOW);
    assert(pos == 0);
    assert(out.len == 0);
    assert(elapsed < 10.0);

    // A megabyte of the shortcut z.
    var zeros: u8[>..] = [];
    zeros.resize(MEGABYTE, 'z');
    var bytes: u8[>..] = [];
    let start2 = clock();
    let code2, pos2 = encoding::ascii85_decode(bytes, zeros, strict);
    let elapsed2 = clock() - start2;
    assert(code2 == encoding::ERR_OK);
    assert(bytes.len == MEGABYTE * 4);
    assert(elapsed2 < 10.0);

    // A megabyte of bytes encodes and decodes in under one second.
    var raw: u8[>..] = [];
    raw.resize(MEGABYTE, 'z');
    var text: u8[>..] = [];
    let start3 = clock();
    encoding::ascii85_encode(text, raw, strict);
    var back: u8[>..] = [];
    let code3, pos3 = encoding::ascii85_decode(back, text, strict);
    let elapsed3 = clock() - start3;
    assert(code3 == encoding::ERR_OK);
    assert(back == raw);
    assert(elapsed3 < 1.0);

    // The same for the base85 codec.
    var text2: u8[>..] = [];
    let start4 = clock();
    encoding::base85_encode(text2, raw, strict);
    var back2: u8[>..] = [];
    let code4, pos4 = encoding::base85_decode(back2, text2, strict);
    let elapsed4 = clock() - start4;
    assert(code4 == encoding::ERR_OK);
    assert(back2 == raw);
    assert(elapsed4 < 1.0);
}

// The text that Python base64.z85encode writes for the test pattern.
// Its prefixes are the texts of the shorter lengths.
const Z85_WANT: const u8[:] = "3OUObPtY$7gGY71:lTx@ty-M))?v=*Gq^5=7D=bXTi*ITkv/RN!a:}Ixn<aD}YFsxKf)Qtbs(WmX7?0h";

// test_z85 pins the Z85 codec of RFC 32.
fn test_z85() {
    let strict = encoding::strict_options();
    let text = encoding::text_options();
    let vec: u8[8] = [0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B];

    // The test vector of RFC 32.
    var out: u8[>..] = [];
    let c0, p0 = encoding::z85_encode(out, vec[..], strict);
    assert(c0 == encoding::ERR_OK && p0 == -1);
    assert(out == "HelloWorld");
    let u2: u8[4] = [255, 255, 255, 255];
    var empty: u8[>..] = [];
    let c1, p1 = encoding::z85_encode(empty, "", strict);
    assert(c1 == encoding::ERR_OK && empty.len == 0);

    // The encoder refuses a length that is not a multiple of 4.
    var keep: u8[>..] = [7];
    let c2, p2 = encoding::z85_encode(keep, "abc", strict);
    assert(c2 == encoding::ERR_BAD_LENGTH && p2 == 0 && keep.len == 1);
    let c3, p3 = encoding::z85_encode(keep, "abcde", strict);
    assert(c3 == encoding::ERR_BAD_LENGTH && p3 == 4 && keep.len == 1);

    // The decoder.
    var back: u8[>..] = [];
    let c4, p4 = encoding::z85_decode(back, "HelloWorld", strict);
    assert(c4 == encoding::ERR_OK && p4 == -1);
    assert(back == vec[..]);
    var ff: u8[>..] = [];
    encoding::z85_decode(ff, "%nSc0", strict);
    assert(ff == u2[..]);

    // The faults and their positions. The buffer keeps its bytes.
    var b: u8[>..] = [9];
    let c5, p5 = encoding::z85_decode(b, "#####", strict);
    assert(c5 == encoding::ERR_OVERFLOW && p5 == 0 && b.len == 1);
    let c6, p6 = encoding::z85_decode(b, "abcd", strict);
    assert(c6 == encoding::ERR_BAD_LENGTH && p6 == 0 && b.len == 1);
    let c7, p7 = encoding::z85_decode(b, "HelloWorldabcd", strict);
    assert(c7 == encoding::ERR_BAD_LENGTH && p7 == 10 && b.len == 1);
    let c8, p8 = encoding::z85_decode(b, "ab,dee", strict);
    assert(c8 == encoding::ERR_INVALID_CHAR && p8 == 2 && b.len == 1);
    // The bad byte at 1 comes before the short group at 5.
    let c9, p9 = encoding::z85_decode(b, "a\"bcdefg", strict);
    assert(c9 == encoding::ERR_INVALID_CHAR && p9 == 1);
    // A character of ASCII85 outside the Z85 alphabet.
    let c10, p10 = encoding::z85_decode(b, "~~~~~", strict);
    assert(c10 == encoding::ERR_INVALID_CHAR && p10 == 0);
    // The value 2 to the power of 32.
    let c11, p11 = encoding::z85_decode(b, "%nSc1", strict);
    assert(c11 == encoding::ERR_OVERFLOW && p11 == 0);

    // The white space.
    let c12, p12 = encoding::z85_decode(b, "Hello World", strict);
    assert(c12 == encoding::ERR_INVALID_CHAR && p12 == 5 && b.len == 1);
    var sp: u8[>..] = [];
    let c13, p13 = encoding::z85_decode(sp, "Hel\r\nlo Wor ld", text);
    assert(c13 == encoding::ERR_OK && sp == vec[..]);


    // Every length from 0 to 64 bytes round-trips. The text is 5/4 as long.
    var n: i64 = 0;
    while n <= 64 {
        var src: u8[>..] = [];
        var k: i64 = 0;
        while k < n { src.push(((k * 37 + 11) % 256) as u8); k = k + 1; }
        var enc: u8[>..] = [];
        let ce, pe = encoding::z85_encode(enc, src, strict);
        if n % 4 == 0 {
            assert(ce == encoding::ERR_OK && enc.len == n / 4 * 5);
            assert(enc == Z85_WANT[..n / 4 * 5]);
            var dec: u8[>..] = [];
            let cd, pd = encoding::z85_decode(dec, enc, strict);
            assert(cd == encoding::ERR_OK && dec == src);
        } else {
            assert(ce == encoding::ERR_BAD_LENGTH && enc.len == 0);
        }
        n = n + 1;
    }

    // A megabyte of the character # gives an overflow, fast.
    var bad: u8[>..] = [];
    bad.resize(MEGABYTE, '#');
    var hold: u8[>..] = [];
    let start = clock();
    let c14, p14 = encoding::z85_decode(hold, bad, strict);
    assert(c14 == encoding::ERR_OVERFLOW && p14 == 0 && hold.len == 0);
    assert(clock() - start < 10.0);
}

// test_alphabets pins the Crockford codec, the map01 option and the
// custom alphabet.
fn test_alphabets() {
    let strict = encoding::strict_options();
    let text = encoding::text_options();

    // Crockford: the vectors, no padding, either case, the letters I, L, O.
    var out: u8[>..] = [];
    encoding::base32crockford_encode(out, "foobar", strict);
    assert(out == "CSQPYRK1E8");
    var out2: u8[>..] = [];
    encoding::base32crockford_encode(out2, "f", strict);
    assert(out2 == "CR");
    var out3: u8[>..] = [];
    var low = strict;
    low.lower = true;
    encoding::base32crockford_encode(out3, "foobar", low);
    assert(out3 == "csqpyrk1e8");
    var back: u8[>..] = [];
    let c0, p0 = encoding::base32crockford_decode(back, "csqpyrk1e8", strict);
    assert(c0 == encoding::ERR_OK && back == "foobar");
    var b2: u8[>..] = [];
    let c1, p1 = encoding::base32crockford_decode(b2, "CSQPYRKIE8", strict);
    assert(c1 == encoding::ERR_OK && b2 == "foobar");
    var b3: u8[>..] = [];
    let c2, p2 = encoding::base32crockford_decode(b3, "CSQPYRKlE8", strict);
    assert(c2 == encoding::ERR_OK && b3 == "foobar");
    var z1: u8[>..] = [];
    var z2: u8[>..] = [];
    encoding::base32crockford_decode(z1, "0O0O0O0O", strict);
    encoding::base32crockford_decode(z2, "00000000", strict);
    assert(z1 == z2 && z1.len == 5);

    // The faults. The letter U is not in the alphabet. The padding is a bad byte.
    var keep: u8[>..] = [7];
    let c3, p3 = encoding::base32crockford_decode(keep, "CSQPYRKU", strict);
    assert(c3 == encoding::ERR_INVALID_CHAR && p3 == 7 && keep.len == 1);
    let c4, p4 = encoding::base32crockford_decode(keep, "CR======", strict);
    assert(c4 == encoding::ERR_INVALID_CHAR && p4 == 2 && keep.len == 1);
    let c5, p5 = encoding::base32crockford_decode(keep, "CS", strict);
    assert(c5 == encoding::ERR_NON_CANONICAL && p5 == 1 && keep.len == 1);
    let c6, p6 = encoding::base32crockford_decode(keep, "C", strict);
    assert(c6 == encoding::ERR_BAD_LENGTH && p6 == 0);

    // The hyphen is skipped only on request.
    let c7, p7 = encoding::base32crockford_decode(keep, "CSQP-YRK1E8", strict);
    assert(c7 == encoding::ERR_INVALID_CHAR && p7 == 4 && keep.len == 1);
    var b4: u8[>..] = [];
    let c8, p8 = encoding::base32crockford_decode(b4, "CSQP-YRK1E8", text);
    assert(c8 == encoding::ERR_OK && b4 == "foobar");
    // The base32 decoder never skips a hyphen.
    let c9, p9 = encoding::base32_decode(keep, "MZXW-6YTB", text);
    assert(c9 == encoding::ERR_INVALID_CHAR && p9 == 4);

    // Round trip of Crockford for the lengths 0 to 40.
    var n: i64 = 0;
    while n <= 40 {
        var src: u8[>..] = [];
        var k: i64 = 0;
        while k < n { src.push(((k * 53 + 7) % 256) as u8); k = k + 1; }
        var e: u8[>..] = [];
        encoding::base32crockford_encode(e, src, strict);
        assert(e.len == (n * 8 + 4) / 5);
        var d: u8[>..] = [];
        let cd, pd = encoding::base32crockford_decode(d, e, strict);
        assert(cd == encoding::ERR_OK && d == src);
        n = n + 1;
    }

    // map01: 0 reads as O and 1 reads as I or L. Off by default.
    var m1 = strict;
    m1.map01 = 'I';
    var d1: u8[>..] = [];
    let c10, p10 = encoding::base32_decode(d1, "MZXW6YTB01======", m1);
    assert(c10 == encoding::ERR_OK && d1 == "foobar");
    var m2 = strict;
    m2.map01 = 'L';
    var d2: u8[>..] = [];
    let c11, p11 = encoding::base32_decode(d2, "1AWBMCYF", m2);
    let want_l: u8[5] = [0x58, 0x2c, 0x16, 0x0b, 0x05];
    assert(c11 == encoding::ERR_OK && d2 == want_l[..]);
    // The letter I is not the digit 1 under the letter L.
    var d3: u8[>..] = [];
    let c11b, p11b = encoding::base32_decode(d3, "1QRBCCAE", m1);
    let want_i: u8[5] = [0x44, 0x22, 0x11, 0x08, 0x04];
    assert(c11b == encoding::ERR_OK && d3 == want_i[..]);
    let c12, p12 = encoding::base32_decode(keep, "MZXW6YTB01======", strict);
    assert(c12 == encoding::ERR_INVALID_CHAR && p12 == 8);
    var m3 = strict;
    m3.map01 = 'X';
    let c13, p13 = encoding::base32_decode(keep, "MZXW6YTB01======", m3);
    assert(c13 == encoding::ERR_INVALID_CHAR && p13 == 8);
    // The base32hex alphabet holds 0 and 1 already.
    var h1: u8[>..] = [];
    let c14, p14 = encoding::base32hex_decode(h1, "CPNMU===", m1);
    assert(c14 == encoding::ERR_OK && h1 == "foo");

    // A custom alphabet equal to base32hex in lower case.
    let alpha: const u8[:] = "0123456789abcdefghijklmnopqrstuv";
    n = 0;
    while n <= 40 {
        var src: u8[>..] = [];
        var k: i64 = 0;
        while k < n { src.push(((k * 29 + 3) % 256) as u8); k = k + 1; }
        var a: u8[>..] = [];
        var b: u8[>..] = [];
        let ce, pe = encoding::custom32_encode(a, src, alpha, strict);
        encoding::base32hex_encode(b, src, low);
        assert(ce == encoding::ERR_OK && a == b);
        var d: u8[>..] = [];
        let cd, pd = encoding::custom32_decode(d, a, alpha, strict);
        assert(cd == encoding::ERR_OK && d == src);
        n = n + 1;
    }
    // The custom decoder reads each symbol exactly.
    let c15, p15 = encoding::custom32_decode(keep, "CPNMU===", alpha, strict);
    assert(c15 == encoding::ERR_INVALID_CHAR && p15 == 0 && keep.len == 1);

    // A bad alphabet gives a fault and writes nothing.
    let c16, p16 = encoding::custom32_encode(keep, "abc", "0123456789abcdefghijklmnopqrstu", strict);
    assert(c16 == encoding::ERR_BAD_ALPHABET && p16 == 0 && keep.len == 1);
    let c17, p17 = encoding::custom32_encode(keep, "abc", "0123456789abcdefghijklmnopqrstt1", strict);
    assert(c17 == encoding::ERR_BAD_ALPHABET && p17 == 30 && keep.len == 1);
    let c18, p18 = encoding::custom32_decode(keep, "abc", "0123456789 bcdefghijklmnopqrstuv", strict);
    assert(c18 == encoding::ERR_BAD_ALPHABET && p18 == 10);
    let c19, p19 = encoding::custom32_decode(keep, "abc", "0123456789=bcdefghijklmnopqrstuv", strict);
    assert(c19 == encoding::ERR_BAD_ALPHABET && p19 == 10);
}

// stream_encode runs an encoder over the bytes in chunks of a given size.
fn stream_encode(codec: i64, src: const u8[:], chunk: i64, opts: encoding::Options, out: u8[>..]&) -> i64, i64 {
    var s = encoding::encoder_new(codec, opts);
    var off: i64 = 0;
    while off < src.len {
        var end = off + chunk;
        if end > src.len { end = src.len; }
        let code, pos = encoding::stream_write(s, out, src[off..end]);
        if code != encoding::ERR_OK { return code, pos; }
        off = end;
    }
    return encoding::stream_finish(s, out);
}

// stream_decode runs a decoder over the text in chunks of a given size.
fn stream_decode(codec: i64, src: const u8[:], chunk: i64, opts: encoding::Options, out: u8[>..]&) -> i64, i64 {
    var s = encoding::decoder_new(codec, opts);
    var off: i64 = 0;
    while off < src.len {
        var end = off + chunk;
        if end > src.len { end = src.len; }
        let code, pos = encoding::stream_write(s, out, src[off..end]);
        if code != encoding::ERR_OK { return code, pos; }
        off = end;
    }
    return encoding::stream_finish(s, out);
}

// one_encode runs the call of the package that matches a stream codec.
fn one_encode(codec: i64, src: const u8[:], opts: encoding::Options, out: u8[>..]&) -> i64 {
    if codec == encoding::STREAM_BASE32 { encoding::base32_encode(out, src, opts); }
    else if codec == encoding::STREAM_BASE32HEX { encoding::base32hex_encode(out, src, opts); }
    else if codec == encoding::STREAM_CROCKFORD { encoding::base32crockford_encode(out, src, opts); }
    else if codec == encoding::STREAM_HEX { encoding::hex_encode(out, src, opts); }
    else if codec == encoding::STREAM_ASCII85 { encoding::ascii85_encode(out, src, opts); }
    else if codec == encoding::STREAM_BASE85 { encoding::base85_encode(out, src, opts); }
    else {
        let code, pos = encoding::z85_encode(out, src, opts);
        return code;
    }
    return encoding::ERR_OK;
}

// one_decode runs the call of the package that matches a stream codec.
fn one_decode(codec: i64, src: const u8[:], opts: encoding::Options, out: u8[>..]&) -> i64, i64 {
    if codec == encoding::STREAM_BASE32 { return encoding::base32_decode(out, src, opts); }
    if codec == encoding::STREAM_BASE32HEX { return encoding::base32hex_decode(out, src, opts); }
    if codec == encoding::STREAM_CROCKFORD { return encoding::base32crockford_decode(out, src, opts); }
    if codec == encoding::STREAM_HEX { return encoding::hex_decode(out, src, opts); }
    if codec == encoding::STREAM_ASCII85 { return encoding::ascii85_decode(out, src, opts); }
    if codec == encoding::STREAM_BASE85 { return encoding::base85_decode(out, src, opts); }
    return encoding::z85_decode(out, src, opts);
}

// test_streams proves that a stream gives the result of one call, for
// every codec, every length and several chunk sizes.
fn test_streams() {
    let strict = encoding::strict_options();
    var codec: i64 = 0;
    while codec <= encoding::STREAM_Z85 {
        if codec == encoding::STREAM_CUSTOM32 { codec = codec + 1; continue; }
        var n: i64 = 0;
        while n <= 60 {
            var src: u8[>..] = [];
            var k: i64 = 0;
            while k < n { src.push(((k * 71 + 5) % 256) as u8); k = k + 1; }
            if n > 8 { src[3] = 0; src[4] = 0; src[5] = 0; src[6] = 0; }
            var chunk: i64 = 1;
            while chunk <= 13 {
                var want: u8[>..] = [];
                let wc = one_encode(codec, src, strict, want);
                var got: u8[>..] = [];
                let gc, gp = stream_encode(codec, src, chunk, strict, got);
                if wc == encoding::ERR_OK {
                    assert(gc == encoding::ERR_OK);
                    assert(got == want);
                    // The text reads back through a stream too.
                    var back: u8[>..] = [];
                    let dc, dp = stream_decode(codec, want, chunk, strict, back);
                    assert(dc == encoding::ERR_OK);
                    assert(back == src);
                } else {
                    // Z85 refuses a length that is not a multiple of 4.
                    assert(gc == wc);
                    assert(got.len == (src.len / 4) * 5);
                }
                chunk = chunk + 3;
            }
            n = n + 1;
        }
        codec = codec + 1;
    }

    // A fault gives the place of the one-shot call and keeps the buffer.
    var out: u8[>..] = [9];
    let c1, p1 = stream_decode(encoding::STREAM_BASE32, "MZXW6YTBOI======MZXW", 3, strict, out);
    var o2: u8[>..] = [9];
    let c2, p2 = encoding::base32_decode(o2, "MZXW6YTBOI======MZXW", strict);
    assert(c1 == c2 && p1 == p2);
    assert(c1 == encoding::ERR_BAD_PADDING);
    var o3: u8[>..] = [];
    let c3, p3 = stream_decode(encoding::STREAM_Z85, "HelloWorld%nSc0##", 4, strict, o3);
    assert(c3 == encoding::ERR_BAD_LENGTH && p3 == 15);
    var o4: u8[>..] = [];
    let c4, p4 = stream_decode(encoding::STREAM_Z85, "HelloWorld#####%nSc0", 2, strict, o4);
    assert(c4 == encoding::ERR_OVERFLOW && p4 == 10);
    assert(o4.len == 8);
    var o5: u8[>..] = [];
    let c5, p5 = stream_decode(encoding::STREAM_ASCII85, "zz!!!!!zA", 1, strict, o5);
    assert(c5 == encoding::ERR_BAD_LENGTH);

    // A bad byte inside a group gives the fault of one call.
    var o13: u8[>..] = [];
    let c13a, p13a = stream_decode(encoding::STREAM_ASCII85, "azzzzbcde", 9, strict, o13);
    var o14: u8[>..] = [];
    let c13b, p13b = encoding::ascii85_decode(o14, "azzzzbcde", strict);
    assert(c13a == c13b && p13a == p13b && c13a == encoding::ERR_INVALID_CHAR && p13a == 1);
    let c13c, p13c = stream_decode(encoding::STREAM_BASE85, "a,,,,bcde", 1, strict, o13);
    assert(c13c == encoding::ERR_INVALID_CHAR && p13c == 1);
    // A long padding gives the fault of one call.
    var eq: u8[>..] = [];
    eq.resize(300, '=');
    let c13d, p13d = stream_decode(encoding::STREAM_BASE32, eq, 40, strict, o13);
    assert(c13d == encoding::ERR_BAD_PADDING && p13d == 0);

    // Hostile texts give the code and the position of one call, for every
    // chunk size.
    let bad_texts: const u8[:][10] = ["azzzzbcde", "a,,,,bcde", "uuuuu", "#####abcd", "Ac", "A", "MZXW6YTB=", "MZXW6YTBOI======X", "0g", "abcde~"];
    var bt: i64 = 0;
    while bt < 10 {
        var cdc: i64 = 0;
        while cdc <= encoding::STREAM_Z85 {
            if cdc != encoding::STREAM_CUSTOM32 {
                var ch: i64 = 1;
                while ch <= 7 {
                    var ref: u8[>..] = [];
                    let rc, rp = one_decode(cdc, bad_texts[bt], strict, ref);
                    var got: u8[>..] = [];
                    let gc, gp = stream_decode(cdc, bad_texts[bt], ch, strict, got);
                    assert(gc == rc && gp == rp);
                    ch = ch + 2;
                }
            }
            cdc = cdc + 1;
        }
        bt = bt + 1;
    }

    // The fault is sticky.
    var s = encoding::decoder_new(encoding::STREAM_HEX, strict);
    var o6: u8[>..] = [];
    let c6, p6 = encoding::stream_write(s, o6, "0g");
    assert(c6 == encoding::ERR_INVALID_CHAR && p6 == 1);
    let c7, p7 = encoding::stream_write(s, o6, "00");
    assert(c7 == encoding::ERR_INVALID_CHAR && p7 == 1 && o6.len == 0);

    // The white space and the padding across chunks.
    let text = encoding::text_options();
    var o8: u8[>..] = [];
    let c8, p8 = stream_decode(encoding::STREAM_BASE32, "MZXW 6YTB OI== ====", 1, text, o8);
    assert(c8 == encoding::ERR_OK && o8 == "foobar");

    // A custom alphabet.
    var cs = encoding::custom32_encoder_new("0123456789abcdefghijklmnopqrstuv", strict);
    var o9: u8[>..] = [];
    encoding::stream_write(cs, o9, "foo");
    encoding::stream_write(cs, o9, "bar");
    let c9, p9 = encoding::stream_finish(cs, o9);
    var o10: u8[>..] = [];
    encoding::custom32_encode(o10, "foobar", "0123456789abcdefghijklmnopqrstuv", strict);
    assert(c9 == encoding::ERR_OK && o9 == o10);
    var bad = encoding::custom32_decoder_new("aaaa", strict);
    let c10, p10 = encoding::stream_write(bad, o9, "abc");
    assert(c10 == encoding::ERR_BAD_ALPHABET && p10 == 0);

    // A stream is reusable after finish.
    var rs = encoding::encoder_new(encoding::STREAM_HEX, strict);
    var o11: u8[>..] = [];
    encoding::stream_write(rs, o11, "ab");
    encoding::stream_finish(rs, o11);
    encoding::stream_write(rs, o11, "cd");
    encoding::stream_finish(rs, o11);
    assert(o11 == "61626364");

    // A group with more white space than the carry holds is a fault.
    var many: u8[>..] = [];
    many.push('A');
    many.resize(300, ' ');
    var o12: u8[>..] = [];
    let c12, p12 = stream_decode(encoding::STREAM_BASE32, many, 50, text, o12);
    assert(c12 == encoding::ERR_BAD_LENGTH && o12.len == 0);

    // A megabyte in chunks of 1000 bytes.
    var big: u8[>..] = [];
    big.resize(MEGABYTE, 'A');
    var enc: u8[>..] = [];
    let start = clock();
    let c13, p13 = stream_encode(encoding::STREAM_BASE85, big, 1000, strict, enc);
    var dec: u8[>..] = [];
    let c14, p14 = stream_decode(encoding::STREAM_BASE85, enc, 1000, strict, dec);
    assert(c13 == encoding::ERR_OK && c14 == encoding::ERR_OK && dec == big);
    assert(clock() - start < 5.0);
}

// test_options_more pins the separator, the line width, the frame of
// Adobe and the exact case.
fn ad_opts(width: i64) -> encoding::Options {
    var o = encoding::strict_options();
    o.adobe = true;
    o.wrap = width;
    return o;
}

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
    var w10 = ad_opts(10);
    var o10: u8[>..] = [];
    encoding::ascii85_encode(o10, "hello", w10);
    assert(o10 == "<~BOu!rDZ\n~>");
    var w = 1;
    while w < 14 {
        var ow = ad_opts(w);
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

fn main() {
    test_encode();
    test_decode();
    test_round_trip();
    test_faults();
    test_options();
    test_hostile();
    test_encode85();
    test_decode85();
    test_faults85();
    test_options85();
    test_round_trip85();
    test_hostile85();
    test_z85();
    test_alphabets();
    test_streams();
    test_options_more();
    print("all encoding tests pass\n");
    return 0;
}
