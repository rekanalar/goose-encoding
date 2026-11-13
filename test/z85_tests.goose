// The tests of the group z85.
namespace z85_tests;

import std;
import os;
import encoding from "..";

const MEGABYTE: i64 = 1000000;
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
