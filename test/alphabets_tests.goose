// The tests of the group alphabets.
namespace alphabets_tests;

import std;
import os;
import encoding from "..";

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
