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
                                               skip_space: space == 1 };
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
    print("all encoding tests pass\n");
    return 0;
}
