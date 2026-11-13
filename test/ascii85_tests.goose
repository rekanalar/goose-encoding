// The tests of the group ascii85.
namespace ascii85_tests;

import std;
import os;
import encoding from "..";
import common;

const MEGABYTE: i64 = 1000000;

fn test_encode85() {
    // The empty input holds no byte.
    var empty: u8[>..] = [];
    encoding::ascii85_encode(empty, "", encoding::strict_options());
    assert(empty.len == 0);
    var empty2: u8[>..] = [];
    encoding::base85_encode(empty2, "", encoding::strict_options());
    assert(empty2.len == 0);

    // The text that the Python library base64 wrote.
    common::check_a85("A", "5l");
    common::check_a85("AB", "5sb");
    common::check_a85("ABC", "5sdp");
    common::check_a85("ABCD", "5sdq,");
    common::check_a85("hello", "BOu!rDZ");
    common::check_a85("\x00\x00\x00\x00", "z");
    common::check_a85("\xff\xff\xff\xff", "s8W-!");
    common::check_a85("\x00", "!!");
    common::check_a85("\x00\x00", "!!!");
    common::check_a85("\x00\x00\x00", "!!!!");
    common::check_a85("\x01\x02\x03\x04", "!<N?+");

    common::check_b85("A", "K>");
    common::check_b85("AB", "K|%");
    common::check_b85("ABC", "K|(_");
    common::check_b85("ABCD", "K|(`B");
    common::check_b85("hello", "Xk~0{Zv");
    common::check_b85("\x00\x00\x00\x00", "00000");
    common::check_b85("\xff\xff\xff\xff", "|NsC0");
    common::check_b85("\x00", "00");
    common::check_b85("\x00\x00", "000");
    common::check_b85("\x00\x00\x00", "0000");
    common::check_b85("\x01\x02\x03\x04", "0RjUA");
}

fn test_decode85() {
    common::check_read_a85("BOu!rDZ", "hello");
    common::check_read_a85("z", "\x00\x00\x00\x00");
    common::check_read_a85("!!!!!", "\x00\x00\x00\x00");
    common::check_read_a85("Ac", "f");
    common::check_read_a85("00000", "\x2f\x3a\x02\xa3");
    common::check_read_a85("zAc", "\x00\x00\x00\x00f");

    // The < of the frame of Adobe is a digit of ASCII85.
    common::check_read_a85("!<N?+", "\x01\x02\x03\x04");

    common::check_read_b85("Xk~0{Zv", "hello");
    common::check_read_b85("00000", "\x00\x00\x00\x00");
    common::check_read_b85("W&", "f");
    common::check_read_b85("!!!!!", "\xc3\x34\x0a\xe6");

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
